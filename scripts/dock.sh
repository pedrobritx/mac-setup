#!/usr/bin/env bash
#
# scripts/dock.sh — Dock defaults.
#
# Auto-hide, sizing, minimize behavior, recents. The Dock is restarted only
# when a value actually changed.
#
# Dock *contents* (pinned apps) are deliberately not managed: reordering is
# personal and destructive to automate. See docs/POST_INSTALL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="dock"
DEFAULTS_CHANGED=0

# ---------------------------------------------------------------------------
# configure_dock — visibility, size, and behavior.
# ---------------------------------------------------------------------------
configure_dock() {
  defaults_write com.apple.dock autohide bool true \
    "Dock: auto-hide"
  defaults_write com.apple.dock autohide-delay float 0 \
    "Dock: no delay before revealing"
  defaults_write com.apple.dock autohide-time-modifier float 0.4 \
    "Dock: fast reveal animation"
  defaults_write com.apple.dock tilesize int 44 \
    "Dock: icon size 44px"
  defaults_write com.apple.dock magnification bool false \
    "Dock: no magnification"
  defaults_write com.apple.dock minimize-to-application bool true \
    "Dock: minimize windows into their app icon"
  defaults_write com.apple.dock mineffect string "scale" \
    "Dock: 'scale' minimize effect (faster than genie)"
  defaults_write com.apple.dock show-recents bool false \
    "Dock: hide recent applications"
  defaults_write com.apple.dock launchanim bool false \
    "Dock: no bounce animation on launch"
  defaults_write com.apple.dock showhidden bool true \
    "Dock: dim icons of hidden apps"
}

# ---------------------------------------------------------------------------
# apply_changes — restart the Dock only when something changed.
# ---------------------------------------------------------------------------
apply_changes() {
  if [[ "${DEFAULTS_CHANGED}" -eq 0 ]]; then
    log_skip "All Dock defaults already configured."
    report_skip "${MODULE}" "Dock defaults" "all values already set"
    return 0
  fi
  run killall Dock 2>/dev/null || true
  report_ok "${MODULE}" "Dock defaults" "applied and Dock restarted"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if [[ "${MAC_SETUP_ENABLE_DOCK}" != "1" ]]; then
    log_skip "Dock configuration disabled in config/settings.sh."
    report_skip "${MODULE}" "Dock defaults" "disabled in settings"
    return 0
  fi

  configure_dock
  apply_changes
}

main "$@"
