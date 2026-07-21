#!/usr/bin/env bash
#
# lib/run.sh — Command execution and file-operation primitives.
#
# All state-changing actions in this repository go through these helpers so
# that dry-run mode, verbosity, logging, and backups behave identically
# everywhere.
#
# Provides:
#   run           — execute a command, honoring DRY_RUN and VERBOSE
#   run_quiet     — like run, but silences stdout unless VERBOSE=1
#   run_retry     — run with exponential backoff for flaky network operations
#   backup_file   — move an existing file into the timestamped backup area
#   link_file     — idempotent symlink with backup + uninstall manifest
#   ensure_dir    — idempotent mkdir -p
#   confirm       — interactive yes/no prompt (auto-yes with MAC_SETUP_YES=1)

if [[ -n "${_MAC_SETUP_RUN_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_RUN_LOADED=1

# ---------------------------------------------------------------------------
# run <command> [args...]
# Execute a command directly (no eval, arguments preserved). In dry-run mode
# the command is printed instead of executed and the call succeeds.
# Returns the command's exit code.
# ---------------------------------------------------------------------------
run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log_dry "$*"
    return 0
  fi
  log_debug "run: $*"
  "$@"
}

# ---------------------------------------------------------------------------
# run_quiet <command> [args...]
# Like run, but discards stdout unless VERBOSE=1. stderr always passes
# through so real failures stay visible.
# ---------------------------------------------------------------------------
run_quiet() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log_dry "$*"
    return 0
  fi
  log_debug "run: $*"
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    "$@"
  else
    "$@" >/dev/null
  fi
}

# ---------------------------------------------------------------------------
# run_retry <max_attempts> <command> [args...]
# Run a command with exponential backoff (2s, 4s, 8s, ...). Intended for
# network operations (downloads, git push, brew fetch).
# ---------------------------------------------------------------------------
run_retry() {
  local max_attempts="$1"
  shift
  local attempt=1 delay=2

  while true; do
    if run "$@"; then
      return 0
    fi
    if ((attempt >= max_attempts)); then
      log_error "Command failed after ${max_attempts} attempts: $*"
      return 1
    fi
    log_warn "Attempt ${attempt}/${max_attempts} failed; retrying in ${delay}s: $*"
    sleep "${delay}"
    delay=$((delay * 2))
    attempt=$((attempt + 1))
  done
}

# ---------------------------------------------------------------------------
# ensure_dir <path>
# Create a directory (and parents) when missing. Idempotent.
# ---------------------------------------------------------------------------
ensure_dir() {
  local dir="$1"
  if [[ -d "${dir}" ]]; then
    log_debug "directory exists: ${dir}"
    return 0
  fi
  run mkdir -p "${dir}"
  log_success "Created directory ${dir/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# backup_file <path>
# Move an existing file/directory into the backup area for this run,
# preserving its path relative to $HOME so uninstall.sh can restore it.
# No-op when the path does not exist.
# ---------------------------------------------------------------------------
backup_file() {
  local path="$1"
  [[ -e "${path}" || -L "${path}" ]] || return 0

  local rel="${path#"${HOME}"/}"
  local dest="${MAC_SETUP_BACKUP_DIR}/${MAC_SETUP_RUN_ID}/${rel}"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log_dry "backup ${path} -> ${dest}"
    return 0
  fi

  mkdir -p "$(dirname "${dest}")"
  mv "${path}" "${dest}"
  log_info "Backed up ${path/#${HOME}/~} -> ${dest/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# link_file <source> <target>
# Create (or refresh) a symlink target -> source.
#   * Skips when the link already points at source (idempotent).
#   * Backs up any pre-existing regular file/dir at target — never destroys.
#   * Records the link in the manifest so uninstall.sh can remove exactly
#     what this tool created.
# ---------------------------------------------------------------------------
link_file() {
  local source="$1" target="$2"

  if [[ ! -e "${source}" ]]; then
    log_error "link_file: source does not exist: ${source}"
    return 1
  fi

  if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
    log_skip "Already linked: ${target/#${HOME}/~}"
    return 0
  fi

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    log_dry "ln -s ${source} ${target}"
    return 0
  fi

  if [[ -e "${target}" || -L "${target}" ]]; then
    backup_file "${target}"
  fi

  mkdir -p "$(dirname "${target}")"
  ln -s "${source}" "${target}"
  printf '%s\t%s\n' "${target}" "${source}" >>"${MAC_SETUP_LINK_MANIFEST}"
  log_success "Linked ${target/#${HOME}/~} -> ${source/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# confirm <question>
# Interactive yes/no prompt. Returns 0 on yes.
# Non-interactive runs (no TTY) and MAC_SETUP_YES=1 answer yes automatically;
# dry-run answers no to any destructive confirmation.
# ---------------------------------------------------------------------------
confirm() {
  local question="$1" reply

  if [[ "${MAC_SETUP_YES:-0}" == "1" ]]; then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    log_warn "No TTY available; assuming 'yes' for: ${question}"
    return 0
  fi

  printf '%b?%b %s [y/N] ' "${C_YELLOW}" "${C_RESET}" "${question}"
  read -r reply
  [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ---------------------------------------------------------------------------
# defaults_write <domain> <key> <type> <value> [description]
# Idempotent `defaults write`: reads the current value first and only
# writes when it differs, so repeat runs are no-ops and Dock/Finder are
# only restarted when something actually changed.
#
# Type is one of: bool, int, float, string.
# Sets the global DEFAULTS_CHANGED=1 when a write happened, letting callers
# decide whether to restart the affected app.
# ---------------------------------------------------------------------------
defaults_write() {
  local domain="$1" key="$2" type="$3" value="$4"
  local desc="${5:-${domain} ${key}}"

  # Normalize booleans: `defaults read` prints 1/0.
  local expected="${value}"
  if [[ "${type}" == "bool" ]]; then
    case "${value}" in
      true | TRUE | yes | 1) expected="1" ;;
      *) expected="0" ;;
    esac
  fi

  if default_equals "${domain}" "${key}" "${expected}"; then
    log_debug "defaults ok: ${desc}"
    return 0
  fi

  if run defaults write "${domain}" "${key}" "-${type}" "${value}"; then
    log_success "${desc}"
    # Read by the calling module (macos/finder/dock) to decide on restarts.
    # shellcheck disable=SC2034
    DEFAULTS_CHANGED=1
  else
    log_warn "Failed to set: ${desc}"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# defaults_delete <domain> <key> [description]
# Idempotent `defaults delete`: removes a previously written override so the
# system falls back to its stock value. A no-op when the key is not set.
# Sets DEFAULTS_CHANGED=1 when a key was actually removed.
# ---------------------------------------------------------------------------
defaults_delete() {
  local domain="$1" key="$2"
  local desc="${3:-${domain} ${key} removed (system default restored)}"

  if ! defaults read "${domain}" "${key}" >/dev/null 2>&1; then
    log_debug "defaults already absent: ${domain} ${key}"
    return 0
  fi

  if run defaults delete "${domain}" "${key}"; then
    log_success "${desc}"
    # Read by the calling module (macos/finder/dock) to decide on restarts.
    # shellcheck disable=SC2034
    DEFAULTS_CHANGED=1
  else
    log_warn "Failed to delete: ${desc}"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# pref_enabled <CATEGORY_KEY>
# Decide whether one optional preference *category* should be applied.
#
# Each macOS/security tweak is a suggestion the user can accept or skip up
# front on the selection screen (lib/picker.sh exports the choices as
# MAC_SETUP_PREF_<KEY>=1|0), or pin ahead of time in config/settings.sh.
# The default when a category is unset is to APPLY it — the suggested set is
# the favourite config, so a plain non-interactive run still converges on it.
#
# Values (case-insensitive): 0/no/off/false/skip → skip; anything else apply.
# Returns 0 to apply, 1 to skip, so callers can write:
#   pref_enabled KEYBOARD && configure_keyboard
# ---------------------------------------------------------------------------
pref_enabled() {
  local var="MAC_SETUP_PREF_$1" val
  val="${!var:-}"
  case "$(printf '%s' "${val}" | tr '[:upper:]' '[:lower:]')" in
    0 | no | n | off | false | skip) return 1 ;;
    *) return 0 ;;
  esac
}

# ---------------------------------------------------------------------------
# ensure_brew_formula <formula>
# Install a Homebrew formula only when it is not already installed. Accepts
# fully qualified names (user/tap/formula); the installed check uses the
# short name. Returns non-zero when brew is unavailable or install fails.
# ---------------------------------------------------------------------------
ensure_brew_formula() {
  local formula="$1"
  ensure_brew_in_path
  if brew_formula_installed "${formula##*/}"; then
    log_debug "formula already installed: ${formula}"
    return 0
  fi
  if ! has_command brew; then
    [[ "${DRY_RUN:-0}" == "1" ]] && return 0
    log_warn "Homebrew not available; cannot install ${formula}."
    return 1
  fi
  log_info "Installing ${formula} via Homebrew..."
  run_retry 2 brew install --formula "${formula}"
}

# ---------------------------------------------------------------------------
# sudo_keepalive
# Ask for sudo once up front and keep the timestamp fresh for the duration
# of the parent process, so long installs don't stall on a password prompt.
# When stdin is a pipe (curl | bash), prompt on /dev/tty instead so the
# password can still be read.
# ---------------------------------------------------------------------------
sudo_keepalive() {
  if [[ "${DRY_RUN:-0}" == "1" || "${MAC_SETUP_TEST:-0}" == "1" ]]; then
    log_debug "skipping sudo keepalive (dry-run/test mode)"
    return 0
  fi
  local sudo_ok=1
  if sudo -n true 2>/dev/null; then
    sudo_ok=0
  elif [[ -t 0 ]]; then
    sudo -v && sudo_ok=0
  elif [[ -r /dev/tty ]]; then
    # shellcheck disable=SC2024  # the redirect feeds sudo's password prompt
    sudo -v </dev/tty && sudo_ok=0
  fi
  if [[ "${sudo_ok}" -ne 0 ]]; then
    log_warn "Could not obtain sudo; steps that need it will prompt or fail."
    return 0
  fi
  # Refresh the sudo timestamp every 50s until the parent process exits.
  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" 2>/dev/null || exit
  done &
}
