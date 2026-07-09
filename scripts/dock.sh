#!/usr/bin/env bash
#
# scripts/dock.sh — Dock defaults.
#
# Visibility, sizing, magnification, minimize behavior, recents, window
# tabbing, and hot corners. The Dock is restarted only when a value
# actually changed.
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
#
# Values follow the owner's documented System Settings preferences
# (Desktop & Dock): Dock always visible, size ≈ 20%, magnification ≈ 50%,
# suggested/recent apps shown, windows minimized into the app icon.
# The slider percentages map onto the 16–128 px tilesize/largesize range.
# Earlier auto-hide/animation-speed overrides are actively removed so the
# stock reveal behavior returns.
# ---------------------------------------------------------------------------
configure_dock() {
  defaults_write com.apple.dock autohide bool false \
    "Dock: always visible (no auto-hide)"
  defaults_delete com.apple.dock autohide-delay \
    "Dock: reveal delay back to macOS default"
  defaults_delete com.apple.dock autohide-time-modifier \
    "Dock: reveal animation speed back to macOS default"
  defaults_delete com.apple.dock launchanim \
    "Dock: launch animation back to macOS default"
  defaults_write com.apple.dock tilesize int 38 \
    "Dock: icon size 38px (~20%)"
  defaults_write com.apple.dock magnification bool true \
    "Dock: magnification enabled"
  defaults_write com.apple.dock largesize int 72 \
    "Dock: magnified icon size 72px (~50%)"
  defaults_write com.apple.dock minimize-to-application bool true \
    "Dock: minimize windows into their app icon"
  defaults_write com.apple.dock mineffect string "scale" \
    "Dock: 'scale' minimize effect (faster than genie)"
  defaults_write com.apple.dock show-recents bool true \
    "Dock: show suggested and recent apps"
  defaults_write com.apple.dock showhidden bool true \
    "Dock: dim icons of hidden apps"
}

# ---------------------------------------------------------------------------
# configure_windows — window behaviors from the same System Settings pane.
# ---------------------------------------------------------------------------
configure_windows() {
  defaults_write NSGlobalDomain AppleActionOnDoubleClick string "Fill" \
    "Windows: title bar double-click fills the screen"
  defaults_write NSGlobalDomain AppleWindowTabbingMode string "always" \
    "Windows: always prefer tabs when opening documents"
}

# ---------------------------------------------------------------------------
# configure_hot_corners — Desktop & Dock → Hot Corners.
# Corner action codes: 3 = Application Windows, 4 = Desktop,
# 12 = Notification Center, 14 = Quick Note. Modifier 0 = no modifier key.
# ---------------------------------------------------------------------------
configure_hot_corners() {
  defaults_write com.apple.dock wvous-tl-corner int 4 \
    "Hot corner top-left: Desktop"
  defaults_write com.apple.dock wvous-tl-modifier int 0 \
    "Hot corner top-left: no modifier"
  defaults_write com.apple.dock wvous-tr-corner int 12 \
    "Hot corner top-right: Notification Center"
  defaults_write com.apple.dock wvous-tr-modifier int 0 \
    "Hot corner top-right: no modifier"
  defaults_write com.apple.dock wvous-bl-corner int 3 \
    "Hot corner bottom-left: Application Windows"
  defaults_write com.apple.dock wvous-bl-modifier int 0 \
    "Hot corner bottom-left: no modifier"
  defaults_write com.apple.dock wvous-br-corner int 14 \
    "Hot corner bottom-right: Quick Note"
  defaults_write com.apple.dock wvous-br-modifier int 0 \
    "Hot corner bottom-right: no modifier"
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
  configure_windows
  configure_hot_corners
  apply_changes
}

main "$@"
