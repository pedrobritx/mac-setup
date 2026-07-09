#!/usr/bin/env bash
#
# scripts/brew.sh — Homebrew: install, update, and apply the Brewfile.
#
# Steps:
#   1. Install Homebrew when missing (official installer).
#   2. Configure shellenv for this session.
#   3. Update Homebrew and upgrade outdated packages.
#   4. Apply the repository Brewfile with `brew bundle` (taps, formulae,
#      casks, fonts, mas apps).
#
# mas entries in the Brewfile may fail when the App Store is not signed in
# or a paid app is unpurchased; that is tolerated here and reconciled by
# scripts/mas.sh, which routes leftovers to the manual-actions report.

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
# apply_brewfile_entries — per-entry fallback when `brew bundle` fails.
# Homebrew 6's bundle fetch is all-or-nothing: one unavailable entry blocks
# every other package. This walks the Brewfile's formulae and casks one by
# one, skipping anything already installed, so a single bad entry only costs
# itself. mas entries are left to scripts/mas.sh.
# ---------------------------------------------------------------------------
apply_brewfile_entries() {
  local entry failed=0

  while IFS= read -r entry; do
    if brew_formula_installed "${entry##*/}"; then
      log_debug "formula already installed: ${entry}"
      continue
    fi
    if run_retry 2 brew install --formula "${entry}"; then
      report_ok "${MODULE}" "${entry}" "installed individually"
    else
      report_fail "${MODULE}" "${entry}" "brew install failed"
      failed=1
    fi
  done < <(grep -E '^brew "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^brew "([^"]+)".*/\1/')

  while IFS= read -r entry; do
    if brew_cask_installed "${entry}"; then
      log_debug "cask already installed: ${entry}"
      continue
    fi
    if run_retry 2 brew install --cask "${entry}"; then
      report_ok "${MODULE}" "${entry}" "installed individually"
    else
      report_fail "${MODULE}" "${entry}" "brew install --cask failed"
      failed=1
    fi
  done < <(grep -E '^cask "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^cask "([^"]+)".*/\1/')

  if [[ "${failed}" -eq 0 ]]; then
    log_success "All Brewfile formulae and casks installed (individual fallback)."
    report_ok "${MODULE}" "brew bundle fallback" "all formulae and casks installed"
  else
    log_warn "Some Brewfile entries still failed; see the install report."
  fi
}

# ---------------------------------------------------------------------------
# apply_brewfile — `brew bundle` against the repository Brewfile.
# HOMEBREW_BUNDLE_MAS_SKIP is honored in test mode. A non-zero exit is
# reported but not fatal: brew bundle installs everything it can and mas
# leftovers are reconciled by scripts/mas.sh. Because bundle aborts wholesale
# when any single entry is unavailable, a failure triggers the per-entry
# fallback so every installable package still lands.
# ---------------------------------------------------------------------------
apply_brewfile() {
  if [[ ! -f "${MAC_SETUP_BREWFILE}" ]]; then
    report_fail "${MODULE}" "Brewfile" "not found at ${MAC_SETUP_BREWFILE}"
    return 1
  fi

  if has_command brew && brew bundle check --file="${MAC_SETUP_BREWFILE}" >/dev/null 2>&1; then
    log_skip "Brewfile already satisfied."
    report_skip "${MODULE}" "brew bundle" "Brewfile already satisfied"
    return 0
  fi

  log_info "Applying Brewfile (this can take a while on a fresh machine)..."
  if run brew bundle install --file="${MAC_SETUP_BREWFILE}" --no-upgrade; then
    log_success "Brewfile applied."
    report_ok "${MODULE}" "brew bundle" "all entries installed"
  else
    log_warn "brew bundle failed — falling back to installing entries individually."
    apply_brewfile_entries
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  install_homebrew
  update_homebrew
  ensure_taps_trusted
  apply_brewfile
}

main "$@"
