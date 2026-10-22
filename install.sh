#!/usr/bin/env bash
#
# install.sh — mac-setup orchestrator.
#
# Runs every module in dependency order to turn a fresh Mac into a fully
# configured workstation. Safe to run repeatedly: every action is guarded by
# an idempotency check and skipped when already satisfied.
#
# On an interactive terminal a full run starts with a selection screen:
# tick/untick what to install, review the summary, confirm once, and the
# rest runs autonomously with an "X of Y installed" progress readout.
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   -n, --dry-run        Print every state-changing command instead of running it
#   -v, --verbose        Show debug output and full command output
#   -l, --list           List available modules and exit
#   -o, --only <m,...>   Run only the given module(s), in the given order
#   -s, --skip <m,...>   Run everything except the given module(s)
#   -y, --yes            Install everything: skip the selection screen and prompts
#   -b, --britx          Apply "Britx choice" (config/britx-choice.sh) and skip
#                         the selection screen — your favourites, no prompts
#       --selection FILE Use an explicit catalogue-key selection (no shell code)
#   -h, --help           Show this help
#
# Examples:
#   ./install.sh                     # full setup
#   ./install.sh --dry-run           # preview everything, change nothing
#   ./install.sh --only brew,apps    # just Homebrew packages and apps
#   ./install.sh --skip macos        # everything except system defaults
#   ./install.sh --britx             # Britx choice, unattended

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/picker.sh
source "${SCRIPT_DIR}/lib/picker.sh"

# ---------------------------------------------------------------------------
# Module registry — execution order matters:
#   xcode        first: Homebrew needs the Command Line Tools
#   brew         second: everything else is installed through it
#   directories  early: later modules write into ~/Developer etc.
#   verification last: validates the finished machine
# ---------------------------------------------------------------------------
MODULES=(
  xcode
  brew
  directories
  apps
  mas
  ssh
  git
  terminal
  node
  python
  swift
  vscode
  macos
  security
  verification
)

# One-line description per module, shown by --list. Kept in a function (not
# an associative array) for bash 3.2 compatibility — macOS ships bash 3.2.
#
# module_description <module> — print the module's description.
module_description() {
  case "$1" in
    xcode) echo "Xcode Command Line Tools, Xcode, license, xcode-select" ;;
    brew) echo "Homebrew install/update + Brewfile bundle (formulae, casks, fonts, mas)" ;;
    directories) echo "Create the ~/Developer workspace directory layout" ;;
    apps) echo "Verify GUI apps; report non-automatable apps (e.g. Cisco Secure Client)" ;;
    mas) echo "Verify Mac App Store apps; report unpurchased/unavailable ones" ;;
    git) echo "Git identity, defaults, LFS, SSH commit signing, GitHub auth" ;;
    ssh) echo "Ed25519 SSH key (never overwrites), ssh config, GitHub guidance" ;;
    terminal) echo "zsh + Starship + plugins; link shell dotfiles" ;;
    node) echo "Node.js via fnm, pnpm, bun" ;;
    python) echo "Python via uv, pipx" ;;
    swift) echo "Swift toolchain checks, SwiftFormat, SwiftLint" ;;
    vscode) echo "VS Code settings, keybindings-safe config, extensions" ;;
    macos) echo "Minimal stock-first defaults: keyboard, trackpad, Finder, screenshots, Safari" ;;
    security) echo "Firewall, Touch ID for sudo, screen-lock settings" ;;
    verification) echo "Verify the whole installation and render a report" ;;
    *) echo "(no description)" ;;
  esac
}

# ---------------------------------------------------------------------------
# usage — print help extracted from this file's header comment.
# ---------------------------------------------------------------------------
usage() {
  sed -n '/^# Usage:/,/^$/{s/^# \{0,1\}//p;}' "${BASH_SOURCE[0]}"
}

# ---------------------------------------------------------------------------
# list_modules — print the module registry with descriptions.
# ---------------------------------------------------------------------------
list_modules() {
  local m
  printf '%bAvailable modules (in execution order):%b\n\n' "${C_BOLD}" "${C_RESET}"
  for m in "${MODULES[@]}"; do
    printf '  %b%-14s%b %s\n' "${C_CYAN}" "${m}" "${C_RESET}" "$(module_description "${m}")"
  done
}

# ---------------------------------------------------------------------------
# in_list <needle> <items...> — true when needle equals one of items.
# ---------------------------------------------------------------------------
in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done
  return 1
}

# ---------------------------------------------------------------------------
# validate_module <name> — abort with a helpful message on unknown modules.
# ---------------------------------------------------------------------------
validate_module() {
  if ! in_list "$1" "${MODULES[@]}"; then
    log_error "Unknown module: '$1' (run ./install.sh --list to see modules)"
    exit 2
  fi
}

# ---------------------------------------------------------------------------
# run_module <name> — execute scripts/<name>.sh as a subprocess.
# Modules inherit DRY_RUN/VERBOSE/RUN_ID/report paths via the environment.
# A module failure is recorded but does not abort the remaining modules.
# ---------------------------------------------------------------------------
run_module() {
  local module="$1"
  local script="${MAC_SETUP_SCRIPTS_DIR}/${module}.sh"

  if [[ ! -f "${script}" ]]; then
    log_error "Module script missing: ${script}"
    report_fail "install" "${module}" "script not found"
    return 1
  fi

  log_step "Module: ${module} — $(module_description "${module}")"
  if [[ -n "${MAC_SETUP_EVENT_FILE:-}" ]]; then
    printf 'start\t%s\t0\n' "${module}" >>"${MAC_SETUP_EVENT_FILE}"
  fi
  local rc=0
  bash "${script}" || rc=$?
  if [[ -n "${MAC_SETUP_EVENT_FILE:-}" ]]; then
    printf 'finish\t%s\t%s\n' "${module}" "${rc}" >>"${MAC_SETUP_EVENT_FILE}"
  fi
  if [[ "${rc}" -eq 0 ]]; then
    log_debug "module ${module} finished"
    return 0
  fi
  log_error "Module '${module}' exited with status ${rc}; continuing with remaining modules."
  report_fail "install" "${module}" "module exited with status ${rc}"
  return 0 # deliberately swallow: one broken module must not sink the run
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  local only=() skip=() m selection=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) DRY_RUN=1 ;;
      -v | --verbose) VERBOSE=1 ;;
      -y | --yes) MAC_SETUP_YES=1 ;;
      -b | --britx) MAC_SETUP_BRITX=1 ;;
      --selection)
        [[ $# -ge 2 ]] || {
          log_error "--selection requires a file"
          exit 2
        }
        selection="$2"
        shift
        ;;
      -l | --list)
        list_modules
        exit 0
        ;;
      -o | --only)
        [[ $# -ge 2 ]] || {
          log_error "--only requires a value"
          exit 2
        }
        IFS=',' read -r -a only <<<"$2"
        shift
        ;;
      -s | --skip)
        [[ $# -ge 2 ]] || {
          log_error "--skip requires a value"
          exit 2
        }
        IFS=',' read -r -a skip <<<"$2"
        shift
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        usage
        exit 2
        ;;
    esac
    shift
  done

  export DRY_RUN VERBOSE MAC_SETUP_YES="${MAC_SETUP_YES:-0}" \
    MAC_SETUP_BRITX="${MAC_SETUP_BRITX:-0}"

  if [[ -n "${selection}" && (${#only[@]} -gt 0 || ${#skip[@]} -gt 0 || "${MAC_SETUP_BRITX}" == "1") ]]; then
    log_error "--selection cannot be combined with --only, --skip, or --britx"
    exit 2
  fi

  require_macos
  require_not_root
  ensure_state_dirs

  MAC_SETUP_LOG_FILE="${MAC_SETUP_LOG_DIR}/install-${MAC_SETUP_RUN_ID}.log"
  export MAC_SETUP_LOG_FILE

  printf '%b\n' "${C_BOLD}${C_MAGENTA}"
  cat <<'BANNER'
                                       _
  _ __ ___   __ _  ___       ___  ___| |_ _   _ _ __
 | '_ ` _ \ / _` |/ __|_____/ __|/ _ \ __| | | | '_ \
 | | | | | | (_| | (__|_____\__ \  __/ |_| |_| | |_) |
 |_| |_| |_|\__,_|\___|     |___/\___|\__|\__,_| .__/
                                               |_|
BANNER
  printf '%b' "${C_RESET}"
  log_info "macOS $(macos_version) on $(uname -m) — run ${MAC_SETUP_RUN_ID}"
  [[ "${DRY_RUN}" == "1" ]] && log_warn "DRY-RUN mode: no changes will be made."
  log_info "Log: ${MAC_SETUP_LOG_FILE/#${HOME}/~}"

  # Validate module selections before doing anything.
  for m in "${only[@]:-}" "${skip[@]:-}"; do
    [[ -n "${m}" ]] && validate_module "${m}"
  done

  # -------------------------------------------------------------------------
  # Selection — either "Britx choice" applied unattended (--britx), the
  # interactive screen on a real terminal, or the non-interactive path for
  # power-user flags (--only/--skip/--yes) and CI.
  # -------------------------------------------------------------------------
  if [[ -n "${selection}" ]]; then
    export MAC_SETUP_EXPLICIT_SELECTION=1
    picker_catalog
    picker_apply_file "${selection}" || exit 2
    MAC_SETUP_BREWFILE="${MAC_SETUP_STATE_DIR}/active-brewfile-${MAC_SETUP_RUN_ID}"
    picker_write_selection "${MAC_SETUP_BREWFILE}"
    export MAC_SETUP_BREWFILE
    if [[ -n "${PICKER_SKIPPED_MODULES}" ]]; then
      # shellcheck disable=SC2206  # module names never contain spaces
      skip+=(${PICKER_SKIPPED_MODULES})
    fi
    # Explicit browser choices can decline all system/security changes.
    local i selected_macos=0 selected_security=0
    for i in "${!PICK_TYPE[@]}"; do
      [[ "${PICK_ON[i]}" == "1" ]] || continue
      case "${PICK_TYPE[i]}:${PICK_ID[i]}" in
        pref:macos:*) selected_macos=1 ;;
        pref:security:*) selected_security=1 ;;
      esac
    done
    [[ "${selected_macos}" == "1" ]] || skip+=(macos)
    [[ "${selected_security}" == "1" ]] || skip+=(security)
    export MAC_SETUP_EXPLICIT_SELECTION=1
  elif [[ ${#only[@]} -eq 0 && ${#skip[@]} -eq 0 && "${MAC_SETUP_YES}" != "1" ]]; then
    if [[ "${MAC_SETUP_BRITX}" == "1" ]]; then
      log_info "Applying Britx choice (config/britx-choice.sh) — no prompts."
      picker_catalog
      picker_apply_britx
      MAC_SETUP_BREWFILE="${MAC_SETUP_STATE_DIR}/active-brewfile-${MAC_SETUP_RUN_ID}"
      picker_write_selection "${MAC_SETUP_BREWFILE}"
      export MAC_SETUP_BREWFILE
      if [[ -n "${PICKER_SKIPPED_MODULES}" ]]; then
        # shellcheck disable=SC2206  # module names never contain spaces
        skip+=(${PICKER_SKIPPED_MODULES})
      fi
    elif picker_available; then
      log_info "Loading the selection screen (everything starts ticked)..."
      picker_catalog
      if ! picker_run; then
        log_info "Selection cancelled — nothing was installed."
        exit 0
      fi
      if ! picker_confirm; then
        log_info "Not confirmed — nothing was installed. Run ./install.sh to start over."
        exit 0
      fi
      MAC_SETUP_BREWFILE="${MAC_SETUP_STATE_DIR}/active-brewfile-${MAC_SETUP_RUN_ID}"
      picker_write_selection "${MAC_SETUP_BREWFILE}"
      export MAC_SETUP_BREWFILE
      if [[ -n "${PICKER_SKIPPED_MODULES}" ]]; then
        # shellcheck disable=SC2206  # module names never contain spaces
        skip+=(${PICKER_SKIPPED_MODULES})
      fi
    fi
  fi

  # Everything the run will install, for the "X of Y" progress readout.
  MAC_SETUP_PROGRESS_TOTAL="$(grep -cE '^(brew|cask|mas) "' "${MAC_SETUP_BREWFILE}" || true)"
  export MAC_SETUP_PROGRESS_TOTAL

  # Build the effective module list.
  local selected=()
  if [[ ${#only[@]} -gt 0 ]]; then
    selected=("${only[@]}")
  else
    for m in "${MODULES[@]}"; do
      if [[ ${#skip[@]} -gt 0 ]] && in_list "${m}" "${skip[@]}"; then
        log_info "Skipping module '${m}'"
        continue
      fi
      selected+=("${m}")
    done
  fi

  # Transparency: announce the plan before touching anything.
  MAC_SETUP_SELECTED_MODULES=" ${selected[*]} "
  export MAC_SETUP_SELECTED_MODULES
  log_step "Plan — ${#selected[@]} steps, ${MAC_SETUP_PROGRESS_TOTAL} packages"
  for m in "${selected[@]}"; do
    printf '  %b•%b %-14s %s\n' "${C_CYAN}" "${C_RESET}" "${m}" "$(module_description "${m}")"
  done
  printf '\n'

  # Ask for sudo once so system-level steps don't stall mid-run.
  log_info "You may be asked for your password now (used for system-level steps)."
  sudo_keepalive

  local start_ts end_ts
  start_ts="$(date +%s)"

  for m in "${selected[@]}"; do
    run_module "${m}"
  done

  end_ts="$(date +%s)"

  # Render reports and the terminal summary.
  render_install_report
  render_manual_report
  print_summary
  if [[ -n "${MAC_SETUP_PROGRESS_TOTAL}" && "${MAC_SETUP_PROGRESS_TOTAL}" != "0" ]]; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_info "Previewed $(progress_count) of ${MAC_SETUP_PROGRESS_TOTAL} selected packages; this run installed nothing."
    else
      log_info "Packages: $(progress_count) of ${MAC_SETUP_PROGRESS_TOTAL} selected items are on this Mac."
    fi
  fi
  log_info "Finished in $(((end_ts - start_ts) / 60))m $(((end_ts - start_ts) % 60))s."
  log_info "Reports: ${MAC_SETUP_REPORT_DIR/#${HOME}/~}"

  local counts fail
  counts="$(report_counts)"
  fail="$(awk '{print $3}' <<<"${counts}")"
  if [[ "${fail}" != "0" ]]; then
    log_warn "${fail} item(s) failed — see the install report for details."
    exit 1
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_success "Dry-run complete. No apps or system preferences were changed."
  else
    log_success "All done. Restart the terminal (or log out/in) to load everything."
  fi
}

main "$@"
