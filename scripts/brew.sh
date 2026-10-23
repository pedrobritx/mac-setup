#!/usr/bin/env bash
#
# scripts/brew.sh — Homebrew: install, update, and apply the Brewfile.
#
# Steps:
#   1. Install Homebrew when missing (official installer).
#   2. Configure shellenv for this session.
#   3. Update Homebrew and upgrade outdated packages.
#   4. Install every formula and cask from the active Brewfile ONE BY ONE —
#      each item is announced, installed, and confirmed with a running
#      "X of Y" progress count, and one bad entry never blocks the rest
#      (which `brew bundle` cannot guarantee).
#
# Duplicate-copy guard: a cask whose .app already exists (installed from
# the Mac App Store or manually) is skipped — installing the same app from
# two sources is how you end up with two copies of Teams/WhatsApp.
#
# mas entries in the Brewfile are installed by scripts/mas.sh, which routes
# sign-in/purchase problems to the manual-actions report.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="brew"
readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# ---------------------------------------------------------------------------
# install_homebrew — install Homebrew via the official installer if missing.
# ---------------------------------------------------------------------------
install_homebrew() {
  ensure_brew_in_path
  if has_command brew; then
    log_skip "Homebrew already installed ($(brew --version | head -n1))."
    report_skip "${MODULE}" "Homebrew" "already installed"
    return 0
  fi

  if ! xcode_clt_installed; then
    log_error "Xcode Command Line Tools are required before Homebrew."
    report_fail "${MODULE}" "Homebrew" "CLT missing — run ./install.sh --only xcode first"
    return 1
  fi

  log_info "Installing Homebrew (official installer)..."
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "NONINTERACTIVE=1 bash -c \"\$(curl -fsSL ${BREW_INSTALL_URL})\""
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "${BREW_INSTALL_URL}")"
  fi

  ensure_brew_in_path
  if [[ "${DRY_RUN}" == "1" ]] || has_command brew; then
    log_success "Homebrew installed."
    report_ok "${MODULE}" "Homebrew" "installed via official installer"
  else
    report_fail "${MODULE}" "Homebrew" "installer completed but brew not on PATH"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# update_homebrew — refresh Homebrew itself and upgrade outdated packages.
# ---------------------------------------------------------------------------
update_homebrew() {
  has_command brew || { [[ "${DRY_RUN}" == "1" ]] && return 0 || return 1; }

  log_info "Updating Homebrew..."
  if run_retry 3 brew update; then
    report_ok "${MODULE}" "brew update" "updated"
  else
    report_fail "${MODULE}" "brew update" "failed after retries"
  fi

  if [[ "${MAC_SETUP_EXPLICIT_SELECTION:-0}" == "1" ]]; then
    report_skip "${MODULE}" "global upgrades" "explicit selection; unrelated packages are left alone"
    return 0
  fi
  log_info "Upgrading outdated formulae and casks..."
  if run brew upgrade; then
    report_ok "${MODULE}" "brew upgrade" "upgraded"
  else
    report_fail "${MODULE}" "brew upgrade" "some packages failed to upgrade"
  fi
}

# ---------------------------------------------------------------------------
# ensure_taps_trusted — tap and trust every tap declared in the Brewfile.
# Homebrew 6 refuses to load formulae from untrusted third-party taps, and a
# single untrusted tap makes the whole `brew bundle` fetch fail, so this must
# happen before the Brewfile is applied. `brew trust` does not exist on older
# Homebrew versions; failures there are harmless and ignored.
# ---------------------------------------------------------------------------
ensure_taps_trusted() {
  has_command brew || return 0
  local tap
  while IFS= read -r tap; do
    if ! brew_tap_installed "${tap}"; then
      log_info "Tapping ${tap}..."
      run_retry 2 brew tap "${tap}" ||
        report_fail "${MODULE}" "tap ${tap}" "brew tap failed"
    fi
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "brew trust ${tap}"
    elif brew trust "${tap}" </dev/null >/dev/null 2>&1; then
      log_debug "tap trusted: ${tap}"
    else
      # Older Homebrew (no `brew trust` subcommand) or already trusted.
      log_debug "brew trust unavailable or not needed for ${tap}"
    fi
  done < <(grep -E '^tap "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^tap "([^"]+)".*/\1/')
}

# ---------------------------------------------------------------------------
# install_formulae — every `brew "..."` line, one at a time, with progress.
# ---------------------------------------------------------------------------
install_formulae() {
  local entry name
  while IFS= read -r entry; do
    name="${entry##*/}"
    if brew_formula_installed "${name}"; then
      progress_tick "${name}" "already installed"
      report_skip "${MODULE}" "${name}" "already installed"
      continue
    fi
    log_info "Installing ${name}..."
    if run_retry 2 brew install --formula "${entry}"; then
      progress_tick "${name}" "installed"
      report_ok "${MODULE}" "${name}" "installed"
    else
      log_error "${name} failed to install — continuing with the rest."
      report_fail "${MODULE}" "${name}" "brew install failed"
    fi
  done < <(grep -E '^brew "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^brew "([^"]+)".*/\1/')
}

# ---------------------------------------------------------------------------
# install_casks — every `cask "..."` line, one at a time, with progress and
# the duplicate-copy guard (App Store / manual installs win over casks).
# ---------------------------------------------------------------------------
install_casks() {
  local cask app
  while IFS= read -r cask; do
    if brew_cask_installed "${cask}"; then
      progress_tick "${cask}" "already installed"
      report_skip "${MODULE}" "${cask}" "already installed"
      continue
    fi

    app="$(cask_app_name "${cask}")"
    if [[ -n "${app}" ]] && app_installed "${app}"; then
      progress_tick "${cask}" "already installed (${app}.app exists — skipping to avoid a second copy)"
      report_skip "${MODULE}" "${cask}" \
        "${app}.app already installed (App Store or manual) — cask skipped to avoid a duplicate"
      continue
    fi

    log_info "Installing ${cask}..."
    if run_retry 2 brew install --cask "${cask}"; then
      progress_tick "${cask}" "installed"
      report_ok "${MODULE}" "${cask}" "installed"
    else
      log_error "${cask} failed to install — continuing with the rest."
      report_fail "${MODULE}" "${cask}" "brew install --cask failed"
    fi
  done < <(grep -E '^cask "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^cask "([^"]+)".*/\1/')
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if [[ ! -f "${MAC_SETUP_BREWFILE}" ]]; then
    report_fail "${MODULE}" "Brewfile" "not found at ${MAC_SETUP_BREWFILE}"
    exit 1
  fi

  install_homebrew
  update_homebrew
  ensure_taps_trusted
  install_formulae
  install_casks
}

main "$@"
