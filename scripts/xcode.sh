#!/usr/bin/env bash
#
# scripts/xcode.sh — Apple developer tooling.
#
# Handles, in order:
#   1. Xcode Command Line Tools (required by Homebrew and git)
#   2. Full Xcode from the Mac App Store (optional — it is a huge download)
#   3. xcode-select developer directory
#   4. Xcode license acceptance & first-launch setup
#   5. SF Symbols (installed via Brewfile cask; verified here)
#   6. Icon Composer (manual — ships with Xcode 26+/Apple Developer downloads)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="xcode"
readonly XCODE_MAS_ID="497799835"

# ---------------------------------------------------------------------------
# install_command_line_tools — install the Xcode CLT non-interactively when
# possible (via softwareupdate), falling back to the GUI installer.
# ---------------------------------------------------------------------------
install_command_line_tools() {
  if xcode_clt_installed; then
    log_skip "Xcode Command Line Tools already installed."
    report_skip "${MODULE}" "Command Line Tools" "already installed"
    return 0
  fi

  log_info "Installing Xcode Command Line Tools..."
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "softwareupdate --install <Command Line Tools label>"
    return 0
  fi

  # Ask softwareupdate for the CLT package directly — avoids the GUI dialog.
  local placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  touch "${placeholder}"
  local label
  label="$(softwareupdate -l 2>/dev/null |
    grep -o 'Label: Command Line Tools for Xcode-.*' |
    sed 's/^Label: //' | sort -V | tail -n1 || true)"

  if [[ -n "${label}" ]]; then
    run softwareupdate --install "${label}" --verbose
    rm -f "${placeholder}"
  else
    rm -f "${placeholder}"
    log_warn "Could not find a CLT label via softwareupdate; opening the GUI installer."
    run xcode-select --install || true
    log_info "Waiting for the Command Line Tools installation to finish..."
    until xcode_clt_installed; do sleep 15; done
  fi

  if xcode_clt_installed; then
    log_success "Xcode Command Line Tools installed."
    report_ok "${MODULE}" "Command Line Tools" "installed via softwareupdate"
  else
    report_fail "${MODULE}" "Command Line Tools" "installation did not complete"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# install_xcode — install full Xcode from the Mac App Store via mas.
# Optional because of its size; failures degrade to a manual-actions entry.
# ---------------------------------------------------------------------------
install_xcode() {
  if ! pref_enabled FULL_XCODE; then
    report_skip "${MODULE}" "Xcode" "not selected; Command Line Tools are sufficient"
    return 0
  fi
  if app_installed "Xcode"; then
    log_skip "Xcode already installed."
    report_skip "${MODULE}" "Xcode" "already installed"
    return 0
  fi

  if [[ "${MAC_SETUP_EXPLICIT_SELECTION:-0}" == "1" && "${MAC_SETUP_XCODE_FINALISE:-0}" != "1" ]]; then
    log_info "Full Xcode is selected; the App Store module will install it after Homebrew and mas."
    return 0
  fi

  if ! has_command mas || ! mas_signed_in; then
    report_manual "${MODULE}" "Xcode" \
      "https://apps.apple.com/app/xcode/id${XCODE_MAS_ID}" \
      "mas is unavailable or the App Store is not signed in" \
      "Sign in to the App Store, then run: mas install ${XCODE_MAS_ID} (or install from the App Store UI)"
    return 0
  fi

  if ! confirm "Install full Xcode from the App Store? (multi-GB download)"; then
    report_manual "${MODULE}" "Xcode" \
      "https://apps.apple.com/app/xcode/id${XCODE_MAS_ID}" \
      "skipped by user (large download)" \
      "Run: mas install ${XCODE_MAS_ID} when ready"
    return 0
  fi

  if run mas install "${XCODE_MAS_ID}"; then
    log_success "Xcode installed."
    report_ok "${MODULE}" "Xcode" "installed via mas"
  else
    report_manual "${MODULE}" "Xcode" \
      "https://apps.apple.com/app/xcode/id${XCODE_MAS_ID}" \
      "mas install failed (network or Apple ID issue)" \
      "Install Xcode from the App Store UI, then re-run ./install.sh --only xcode"
  fi
}

# ---------------------------------------------------------------------------
# configure_xcode — point xcode-select at Xcode when present, accept the
# license, and run first-launch package installation.
# ---------------------------------------------------------------------------
configure_xcode() {
  if ! app_installed "Xcode"; then
    log_debug "Xcode not installed; leaving xcode-select on the CLT."
    return 0
  fi

  local current
  current="$(xcode-select -p 2>/dev/null || true)"
  if [[ "${current}" != "/Applications/Xcode.app/Contents/Developer" ]]; then
    run sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    report_ok "${MODULE}" "xcode-select" "switched to Xcode.app"
  else
    log_skip "xcode-select already points at Xcode.app."
    report_skip "${MODULE}" "xcode-select" "already configured"
  fi

  if ! run_quiet xcodebuild -license check 2>/dev/null; then
    log_info "Accepting the Xcode license (requires sudo)..."
    if run sudo xcodebuild -license accept; then
      report_ok "${MODULE}" "Xcode license" "accepted"
    else
      report_fail "${MODULE}" "Xcode license" "could not accept automatically"
    fi
  else
    log_skip "Xcode license already accepted."
    report_skip "${MODULE}" "Xcode license" "already accepted"
  fi

  run_quiet xcodebuild -runFirstLaunch || true
}

# ---------------------------------------------------------------------------
# check_companion_apps — SF Symbols (Brewfile cask) and Icon Composer.
# ---------------------------------------------------------------------------
check_companion_apps() {
  if app_installed "SF Symbols" || brew_cask_installed "sf-symbols"; then
    log_skip "SF Symbols present (installed via Brewfile)."
    report_skip "${MODULE}" "SF Symbols" "installed via Brewfile cask"
  else
    log_info "SF Symbols will be installed by the brew module (cask sf-symbols)."
  fi

  if app_installed "Icon Composer"; then
    report_skip "${MODULE}" "Icon Composer" "already installed"
  else
    report_manual "${MODULE}" "Icon Composer" \
      "https://developer.apple.com/download/all/" \
      "distributed with Xcode 26+ / Apple Developer downloads, no Homebrew cask" \
      "Sign in at developer.apple.com → Downloads → search 'Icon Composer' and install, or update to Xcode 26+ which bundles it"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  install_command_line_tools
  install_xcode
  if pref_enabled FULL_XCODE; then
    configure_xcode
    check_companion_apps
  fi
}

main "$@"
