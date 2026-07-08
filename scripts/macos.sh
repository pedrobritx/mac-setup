#!/usr/bin/env bash
#
# scripts/macos.sh — System-wide macOS defaults.
#
# Covers keyboard, trackpad, mouse, Mission Control, Safari, screenshots,
# and developer conveniences. Finder and Dock have their own modules
# (scripts/finder.sh, scripts/dock.sh).
#
# Every write goes through defaults_write (lib/run.sh) so values are only
# changed when they differ — re-runs are silent no-ops. Affected apps are
# restarted only when something changed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="macos"
DEFAULTS_CHANGED=0

# ---------------------------------------------------------------------------
# configure_keyboard — fast key repeat, disable press-and-hold, no auto
# text meddling while coding.
# ---------------------------------------------------------------------------
configure_keyboard() {
  defaults_write NSGlobalDomain KeyRepeat int 2 "Fast key repeat"
  defaults_write NSGlobalDomain InitialKeyRepeat int 15 "Short delay until key repeat"
  defaults_write NSGlobalDomain ApplePressAndHoldEnabled bool false \
    "Disable press-and-hold (enables key repeat everywhere)"
  defaults_write NSGlobalDomain NSAutomaticCapitalizationEnabled bool false \
    "Disable automatic capitalization"
  defaults_write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled bool false \
    "Disable automatic period substitution"
  defaults_write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled bool false \
    "Disable smart quotes (breaks code)"
  defaults_write NSGlobalDomain NSAutomaticDashSubstitutionEnabled bool false \
    "Disable smart dashes (breaks code)"
  defaults_write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled bool false \
    "Disable auto-correct"
}

# ---------------------------------------------------------------------------
# configure_trackpad_mouse — tap to click, sensible tracking.
# ---------------------------------------------------------------------------
configure_trackpad_mouse() {
  defaults_write com.apple.AppleMultitouchTrackpad Clicking bool true \
    "Trackpad: tap to click"
  defaults_write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true \
    "Trackpad (Bluetooth): tap to click"
  defaults_write NSGlobalDomain com.apple.trackpad.forceClick bool true \
    "Trackpad: enable Force Click"
  defaults_write NSGlobalDomain com.apple.mouse.tapBehavior int 1 \
    "Mouse/trackpad: tap registers as click"
}

# ---------------------------------------------------------------------------
# configure_mission_control — predictable Spaces behavior.
# ---------------------------------------------------------------------------
configure_mission_control() {
  defaults_write com.apple.dock mru-spaces bool false \
    "Mission Control: don't rearrange Spaces by recent use"
  defaults_write com.apple.dock expose-group-apps bool true \
    "Mission Control: group windows by application"
  defaults_write NSGlobalDomain AppleSpacesSwitchOnActivate bool true \
    "Switch to a Space with open windows of the activated app"
}

# ---------------------------------------------------------------------------
# configure_screenshots — save into ~/Screenshots as PNG, no shadow.
# ---------------------------------------------------------------------------
configure_screenshots() {
  ensure_dir "${MAC_SETUP_SCREENSHOT_DIR}"
  defaults_write com.apple.screencapture location string \
    "${MAC_SETUP_SCREENSHOT_DIR}" "Screenshots saved to ${MAC_SETUP_SCREENSHOT_DIR/#${HOME}/~}"
  defaults_write com.apple.screencapture type string "png" "Screenshots as PNG"
  defaults_write com.apple.screencapture disable-shadow bool true \
    "No window shadows in screenshots"
}

# ---------------------------------------------------------------------------
# configure_safari — developer mode and privacy basics.
# Safari's container may block `defaults` without Full Disk Access; failures
# here are downgraded to warnings.
# ---------------------------------------------------------------------------
configure_safari() {
  defaults_write com.apple.Safari IncludeDevelopMenu bool true \
    "Safari: show the Develop menu" || true
  defaults_write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey bool true \
    "Safari: developer extras" || true
  defaults_write NSGlobalDomain WebKitDeveloperExtras bool true \
    "Web views: enable inspector" || true
  defaults_write com.apple.Safari AutoOpenSafeDownloads bool false \
    "Safari: don't auto-open downloads" || true
}

# ---------------------------------------------------------------------------
# configure_developer_conveniences — expanded panels, no iCloud default
# save target, crash reporter as notification.
# ---------------------------------------------------------------------------
configure_developer_conveniences() {
  defaults_write NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true \
    "Expand the save panel by default"
  defaults_write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true \
    "Expand the save panel by default (2)"
  defaults_write NSGlobalDomain PMPrintingExpandedStateForPrint bool true \
    "Expand the print panel by default"
  defaults_write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false \
    "Save new documents locally, not to iCloud"
  defaults_write com.apple.CrashReporter UseUNC int 1 \
    "Show crash reports as notifications, not dialogs"
  defaults_write com.apple.LaunchServices LSQuarantine bool false \
    "Disable the 'Are you sure you want to open?' dialog for downloaded apps"
}

# ---------------------------------------------------------------------------
# apply_changes — restart affected system services when needed.
# ---------------------------------------------------------------------------
apply_changes() {
  if [[ "${DEFAULTS_CHANGED}" -eq 0 ]]; then
    log_skip "All system defaults already configured."
    report_skip "${MODULE}" "system defaults" "all values already set"
    return 0
  fi
  run killall SystemUIServer 2>/dev/null || true
  report_ok "${MODULE}" "system defaults" "applied (some changes need logout/restart)"
  log_info "Some keyboard/trackpad changes take effect after logout."
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if [[ "${MAC_SETUP_ENABLE_MACOS_DEFAULTS}" != "1" ]]; then
    log_skip "macOS defaults disabled in config/settings.sh."
    report_skip "${MODULE}" "system defaults" "disabled in settings"
    return 0
  fi

  configure_keyboard
  configure_trackpad_mouse
  configure_mission_control
  configure_screenshots
  configure_safari
  configure_developer_conveniences
  apply_changes
}

main "$@"
