#!/usr/bin/env bash
#
# update.sh — Keep the machine current.
#
#   * pulls the latest mac-setup (so the Brewfile is current)
#   * brew update + upgrade (formulae and casks) + bundle for new entries
#   * Mac App Store upgrades (mas)
#   * VS Code extension updates
#   * Homebrew cache cleanup
#   * outdated-package report
#
# Usage: ./update.sh [--dry-run] [--verbose]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ---------------------------------------------------------------------------
# update_repo — fast-forward this clone so new Brewfile entries apply.
# ---------------------------------------------------------------------------
update_repo() {
  if git -C "${MAC_SETUP_ROOT}" diff --quiet 2>/dev/null &&
    git -C "${MAC_SETUP_ROOT}" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    log_info "Pulling latest mac-setup..."
    run git -C "${MAC_SETUP_ROOT}" pull --ff-only || log_warn "git pull failed; continuing with the local version."
  else
    log_debug "Repo dirty or no upstream — skipping self-update."
  fi
}

# ---------------------------------------------------------------------------
# update_brew — Homebrew itself, all packages, and new Brewfile entries.
# ---------------------------------------------------------------------------
update_brew() {
  ensure_brew_in_path
  if ! has_command brew; then
    log_error "Homebrew not installed — run ./install.sh first."
    exit 1
  fi

  log_step "Homebrew"
  run_retry 3 brew update
  run brew upgrade
  run brew upgrade --cask
  log_info "Installing any new Brewfile entries..."
  run brew bundle install --file="${MAC_SETUP_BREWFILE}" --no-upgrade || true
}

# ---------------------------------------------------------------------------
# update_mas — Mac App Store upgrades.
# ---------------------------------------------------------------------------
update_mas() {
  has_command mas || return 0
  log_step "Mac App Store"
  run mas upgrade || log_warn "mas upgrade failed (App Store signed out?)"
}

# ---------------------------------------------------------------------------
# update_vscode — update all VS Code extensions.
# ---------------------------------------------------------------------------
update_vscode() {
  has_command code || return 0
  log_step "VS Code extensions"
  run_quiet code --update-extensions || log_warn "VS Code extension update failed."
}

# ---------------------------------------------------------------------------
# update_toolchains — Node (fnm) and Python (uv) patch updates.
# ---------------------------------------------------------------------------
update_toolchains() {
  log_step "Toolchains"
  if has_command fnm; then
    run fnm install --lts || true
  fi
  if has_command uv; then
    run uv python install "${MAC_SETUP_PYTHON_VERSION}" || true
  fi
  if has_command pipx; then
    run pipx upgrade-all || true
  fi
}

# ---------------------------------------------------------------------------
# cleanup_caches — reclaim disk from Homebrew.
# ---------------------------------------------------------------------------
cleanup_caches() {
  log_step "Cleanup"
  run brew cleanup --prune=7 -s
  run brew autoremove || true
}

# ---------------------------------------------------------------------------
# report_outdated — what is still outdated after the run.
# ---------------------------------------------------------------------------
report_outdated() {
  log_step "Outdated packages"
  local outdated
  outdated="$(brew outdated --quiet 2>/dev/null || true)"
  if [[ -z "${outdated}" ]]; then
    log_success "Everything is up to date."
  else
    log_warn "Still outdated (pinned or held back):"
    printf '%s\n' "${outdated}"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) DRY_RUN=1 ;;
      -v | --verbose) VERBOSE=1 ;;
      -h | --help)
        sed -n '2,13{s/^# \{0,1\}//p;}' "${BASH_SOURCE[0]}"
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        exit 2
        ;;
    esac
    shift
  done
  export DRY_RUN VERBOSE

  require_macos
  ensure_state_dirs
  MAC_SETUP_LOG_FILE="${MAC_SETUP_LOG_DIR}/update-${MAC_SETUP_RUN_ID}.log"
  export MAC_SETUP_LOG_FILE

  log_info "mac-setup update — run ${MAC_SETUP_RUN_ID}"
  update_repo
  update_brew
  update_mas
  update_vscode
  update_toolchains
  cleanup_caches
  report_outdated
  log_success "Update complete."
}

main "$@"
