#!/usr/bin/env bash
#
# install.sh — mac-setup orchestrator.
#
# Runs every module in dependency order to turn a fresh Mac into a fully
# configured workstation. Safe to run repeatedly: every action is guarded by
# an idempotency check and skipped when already satisfied.
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
#   -y, --yes            Assume "yes" for all confirmation prompts
#   -h, --help           Show this help
#
# Examples:
#   ./install.sh                     # full setup
#   ./install.sh --dry-run           # preview everything, change nothing
#   ./install.sh --only brew,fonts   # just Homebrew packages and fonts
#   ./install.sh --skip macos,dock   # everything except system defaults

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

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
  downloads
  fonts
  apps
  mas
  ssh
  git
  terminal
  node
  python
  swift
  docker
  vscode
  macos
  finder
  dock
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
    downloads) echo "Organize ~/Downloads (Installers folder)" ;;
    fonts) echo "Verify developer fonts installed via Homebrew" ;;
    apps) echo "Verify GUI apps; report non-automatable apps (e.g. Cisco Secure Client)" ;;
    mas) echo "Verify Mac App Store apps; report unpurchased/unavailable ones" ;;
    git) echo "Git identity, defaults, LFS, SSH commit signing, GitHub auth" ;;
    ssh) echo "Ed25519 SSH key (never overwrites), ssh config, GitHub guidance" ;;
    terminal) echo "zsh + Starship + plugins; link shell dotfiles" ;;
    node) echo "Node.js via fnm, pnpm, bun" ;;
    python) echo "Python via uv, pipx" ;;
    swift) echo "Swift toolchain checks, SwiftFormat, SwiftLint" ;;
    docker) echo "Docker Desktop, virtualization check, hello-world" ;;
    vscode) echo "VS Code settings, keybindings-safe config, extensions" ;;
    macos) echo "System defaults: keyboard, trackpad, screenshots, Safari, ..." ;;
    finder) echo "Finder defaults: hidden files, extensions, path bar, list view" ;;
    dock) echo "Dock defaults: autohide, size, recents" ;;
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
  local rc=0
  bash "${script}" || rc=$?
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
  local only=() skip=() m

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) DRY_RUN=1 ;;
      -v | --verbose) VERBOSE=1 ;;
      -y | --yes) MAC_SETUP_YES=1 ;;
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

  export DRY_RUN VERBOSE MAC_SETUP_YES="${MAC_SETUP_YES:-0}"

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

  # Ask for sudo once so system-level steps don't stall mid-run.
  sudo_keepalive

  # Build the effective module list.
  local selected=()
  if [[ ${#only[@]} -gt 0 ]]; then
    selected=("${only[@]}")
  else
    for m in "${MODULES[@]}"; do
      if [[ ${#skip[@]} -gt 0 ]] && in_list "${m}" "${skip[@]}"; then
        log_info "Skipping module '${m}' (--skip)"
        continue
      fi
      selected+=("${m}")
    done
  fi

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
  log_info "Finished in $(((end_ts - start_ts) / 60))m $(((end_ts - start_ts) % 60))s."
  log_info "Reports: ${MAC_SETUP_REPORT_DIR/#${HOME}/~}"

  local counts fail
  counts="$(report_counts)"
  fail="$(awk '{print $3}' <<<"${counts}")"
  if [[ "${fail}" != "0" ]]; then
    log_warn "${fail} item(s) failed — see the install report for details."
    exit 1
  fi
  log_success "All done. Restart the terminal (or log out/in) to load everything."
}

main "$@"
