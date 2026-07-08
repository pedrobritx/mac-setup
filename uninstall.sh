#!/usr/bin/env bash
#
# uninstall.sh — Remove what mac-setup installed. Nothing else.
#
# Scope (each step asks for confirmation):
#   1. Remove the dotfile symlinks this tool created (tracked in a manifest)
#      and restore the most recent backup of each original file.
#   2. Optionally uninstall Brewfile packages (brew bundle cleanup style —
#      shows the list first; only removes Brewfile-declared items).
#   3. Optionally remove mac-setup's own state (~/.local/state/mac-setup).
#
# NEVER touched: user files, documents, SSH keys, git history, App Store
# apps (removing paid apps automatically is a data-loss footgun), macOS
# defaults (restore them via System Settings if desired).
#
# Usage: ./uninstall.sh [--dry-run] [--verbose] [--yes]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ---------------------------------------------------------------------------
# remove_symlinks — undo every link recorded in the manifest, restoring the
# newest backup of the original file when one exists.
# ---------------------------------------------------------------------------
remove_symlinks() {
  log_step "Dotfile symlinks"

  if [[ ! -f "${MAC_SETUP_LINK_MANIFEST}" ]]; then
    log_info "No symlink manifest found — nothing to unlink."
    return 0
  fi

  local target source rel backup
  while IFS=$'\t' read -r target source; do
    [[ -n "${target}" ]] || continue

    if [[ -L "${target}" && "$(readlink "${target}")" == "${source}" ]]; then
      run rm "${target}"
      log_success "Removed link ${target/#${HOME}/~}"
    else
      log_debug "Not our link anymore, leaving alone: ${target}"
      continue
    fi

    # Restore the newest backup of this path, if any.
    rel="${target#"${HOME}"/}"
    backup="$(find "${MAC_SETUP_BACKUP_DIR}" -path "*/${rel}" 2>/dev/null | sort | tail -n1 || true)"
    if [[ -n "${backup}" && ! -e "${target}" ]]; then
      if [[ "${DRY_RUN}" == "1" ]]; then
        log_dry "restore ${backup} -> ${target}"
      else
        mkdir -p "$(dirname "${target}")"
        mv "${backup}" "${target}"
        log_success "Restored original ${target/#${HOME}/~}"
      fi
    fi
  done <"${MAC_SETUP_LINK_MANIFEST}"

  if [[ "${DRY_RUN}" != "1" ]]; then
    rm -f "${MAC_SETUP_LINK_MANIFEST}"
  fi
}

# ---------------------------------------------------------------------------
# remove_packages — optionally uninstall everything the Brewfile declares.
# Shows the list first; each removal is scoped to Brewfile entries only.
# ---------------------------------------------------------------------------
remove_packages() {
  log_step "Homebrew packages"
  ensure_brew_in_path
  if ! has_command brew; then
    log_info "Homebrew not installed — nothing to remove."
    return 0
  fi

  log_info "The Brewfile declares the following installed items:"
  brew bundle list --file="${MAC_SETUP_BREWFILE}" --all 2>/dev/null || true

  if ! confirm "Uninstall ALL of the packages/apps above?"; then
    log_info "Keeping Homebrew packages."
    return 0
  fi

  local formula cask
  while IFS= read -r cask; do
    if brew_cask_installed "${cask}"; then
      run brew uninstall --cask "${cask}" || log_warn "Could not uninstall cask ${cask}"
    fi
  done < <(grep -E '^cask "' "${MAC_SETUP_BREWFILE}" | sed -E 's/^cask "([^"]+)".*/\1/')

  while IFS= read -r formula; do
    if brew_formula_installed "${formula##*/}"; then
      run brew uninstall "${formula}" || log_warn "Could not uninstall ${formula} (may be a dependency)"
    fi
  done < <(grep -E '^brew "' "${MAC_SETUP_BREWFILE}" | sed -E 's/^brew "([^"]+)".*/\1/')

  run brew autoremove || true
  log_info "Homebrew itself was left installed. Remove it with the official"
  log_info "uninstaller if desired: https://github.com/homebrew/install#uninstall-homebrew"
  log_info "Mac App Store apps were left installed — drag them to Trash if unwanted."
}

# ---------------------------------------------------------------------------
# remove_state — optionally delete mac-setup's logs/reports/backups.
# ---------------------------------------------------------------------------
remove_state() {
  log_step "mac-setup state"
  [[ -d "${MAC_SETUP_STATE_DIR}" ]] || return 0

  if confirm "Delete mac-setup state (logs, reports, dotfile backups) at ${MAC_SETUP_STATE_DIR/#${HOME}/~}?"; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "rm -rf ${MAC_SETUP_STATE_DIR}"
    else
      rm -rf "${MAC_SETUP_STATE_DIR}"
      log_success "State removed."
    fi
  else
    log_info "Keeping state directory."
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
      -y | --yes) MAC_SETUP_YES=1 ;;
      -h | --help)
        sed -n '2,18{s/^# \{0,1\}//p;}' "${BASH_SOURCE[0]}"
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        exit 2
        ;;
    esac
    shift
  done
  export DRY_RUN VERBOSE MAC_SETUP_YES="${MAC_SETUP_YES:-0}"

  require_macos
  ensure_state_dirs

  log_warn "This removes things mac-setup installed. User files are never touched."
  if ! confirm "Continue with uninstall?"; then
    log_info "Aborted."
    exit 0
  fi

  remove_symlinks
  remove_packages
  remove_state
  log_success "Uninstall finished. The repository clone itself was not deleted."
}

main "$@"
