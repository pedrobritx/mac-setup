#!/usr/bin/env bash
#
# scripts/apps.sh — GUI applications.
#
# Casks are declared in the Brewfile and installed by scripts/brew.sh. This
# module reconciles the result:
#   * retries any cask that brew bundle missed (individually, so one bad
#     cask cannot block the rest),
#   * records apps that cannot be automated at all (no cask, no Mac App
#     Store listing) into the manual-actions report with URL + steps.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="apps"

# ---------------------------------------------------------------------------
# brewfile_app_casks — print non-font casks declared in the Brewfile.
# ---------------------------------------------------------------------------
brewfile_app_casks() {
  grep -E '^cask "' "${MAC_SETUP_BREWFILE}" |
    grep -v '"font-' |
    sed -E 's/^cask "([^"]+)".*/\1/'
}

# ---------------------------------------------------------------------------
# reconcile_casks — ensure every Brewfile cask is installed; retry misses.
# ---------------------------------------------------------------------------
reconcile_casks() {
  local cask
  while IFS= read -r cask; do
    if brew_cask_installed "${cask}"; then
      log_skip "${cask} already installed."
      report_skip "${MODULE}" "${cask}" "already installed"
      continue
    fi

    log_info "Installing cask: ${cask}"
    if run_retry 2 brew install --cask "${cask}"; then
      report_ok "${MODULE}" "${cask}" "installed"
    else
      report_manual "${MODULE}" "${cask}" \
        "https://formulae.brew.sh/cask/${cask}" \
        "cask installation failed (may require Rosetta, password, or be gone from the cask repo)" \
        "Check 'brew info --cask ${cask}' and install manually if needed"
    fi
  done < <(brewfile_app_casks)
}

# ---------------------------------------------------------------------------
# report_unautomatable_apps — apps with no Homebrew cask or MAS listing.
# These always land in the manual-actions report with official links.
# ---------------------------------------------------------------------------
report_unautomatable_apps() {
  if app_installed "VMware Fusion"; then
    log_skip "VMware Fusion already installed."
    report_skip "${MODULE}" "VMware Fusion" "already installed"
  else
    report_manual "${MODULE}" "VMware Fusion" \
      "https://support.broadcom.com/group/ecx/free-downloads" \
      "the vmware-fusion cask was removed from homebrew/cask; Broadcom now distributes Fusion only through its support portal" \
      "Create a free Broadcom account, download 'VMware Fusion' from the free downloads page, and run the installer"
  fi

  if app_installed "Cisco Secure Client"; then
    log_skip "Cisco Secure Client already installed."
    report_skip "${MODULE}" "Cisco Secure Client" "already installed"
  else
    report_manual "${MODULE}" "Cisco Secure Client" \
      "https://www.cisco.com/c/en/us/support/security/secure-client-5/model.html" \
      "licensed per-organization; the installer must come from your IT department or VPN portal" \
      "Download the macOS installer from your organization's VPN portal (or IT), run the .pkg, then enter your company VPN profile"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  if ! has_command brew && [[ "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "apps" "Homebrew not installed — run the brew module first"
    exit 1
  fi

  reconcile_casks
  report_unautomatable_apps
}

main "$@"
