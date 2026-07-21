#!/usr/bin/env bash
#
# scripts/macos.sh — macOS defaults: minimal, stock-first, performance-safe.
#
# This one module now owns every `defaults` write (Finder and Dock included).
# The rule that keeps a Mac feeling brand new:
#
#   NEVER override window management, Mission Control, Spaces, animations,
#   or rendering. Overrides in that area — hot corners, forced window
#   tabbing, title-bar double-click actions, Dock magnification, minimize
#   effects, animation-speed hacks — are exactly what made earlier versions
#   of this repo glitch: full-screen management, Mission Control, window
#   sizing, and animation speed all misbehaved.
#
# What remains is a small set of purely functional preferences: typing,
# tap-to-click, Finder navigation, screenshot location, Safari's Develop
# menu, and expanded save panels. Everything visual stays stock.
#
# remove_legacy_overrides additionally deletes every key earlier versions
# wrote, so running this module on a previously-tweaked Mac restores stock
# behavior. On a freshly formatted machine every delete is a silent no-op.
#
# Every write goes through defaults_write (lib/run.sh) so values are only
# changed when they differ — re-runs are silent no-ops, and Finder/Dock are
# restarted only when something actually changed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="macos"
DEFAULTS_CHANGED=0

# ---------------------------------------------------------------------------
# remove_legacy_overrides — restore stock behavior wherever earlier versions
# of mac-setup (or classic "speed up your Mac" guides) left overrides behind.
# ---------------------------------------------------------------------------
remove_legacy_overrides() {
  local key

  # Mission Control, Spaces, hot corners, and Dock behavior overrides.
  for key in mru-spaces expose-group-apps expose-animation-duration \
    autohide autohide-delay autohide-time-modifier launchanim \
    magnification largesize mineffect minimize-to-application \
    show-recents showhidden \
    wvous-tl-corner wvous-tl-modifier wvous-tr-corner wvous-tr-modifier \
    wvous-bl-corner wvous-bl-modifier wvous-br-corner wvous-br-modifier; do
    defaults_delete com.apple.dock "${key}" \
      "Dock/Mission Control: ${key} back to macOS default"
  done

  # System-wide window-management and animation overrides.
  for key in AppleSpacesSwitchOnActivate AppleActionOnDoubleClick \
    AppleWindowTabbingMode NSAutomaticWindowAnimationsEnabled \
    NSWindowResizeTime com.apple.trackpad.forceClick; do
    defaults_delete NSGlobalDomain "${key}" \
      "System: ${key} back to macOS default"
  done

  # Finder overrides. Hidden files and the status bar stay OFF (stock);
  # toggle hidden files any time with Cmd+Shift+. or the showfiles alias.
  for key in AppleShowAllFiles ShowStatusBar ShowExternalHardDrivesOnDesktop \
    FXEnableExtensionChangeWarning ShowRecentTags DisableAllAnimations; do
    defaults_delete com.apple.finder "${key}" \
      "Finder: ${key} back to macOS default"
  done

  # One-off tweaks that fought the stock experience.
  defaults_delete com.apple.LaunchServices LSQuarantine \
    "Gatekeeper download confirmation back to macOS default"
  defaults_delete com.apple.CrashReporter UseUNC \
    "Crash reporter back to macOS default"
  defaults_delete com.apple.screencapture disable-shadow \
    "Screenshot window shadow back to macOS default"
  defaults_delete com.apple.screencapture type \
    "Screenshot format back to macOS default (PNG)"
}

# ---------------------------------------------------------------------------
# configure_keyboard — fast key repeat, disable press-and-hold, no auto
# text meddling while coding. Typing-only: no visual/animation impact.
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
# configure_trackpad — tap to click. Everything else stays stock.
# ---------------------------------------------------------------------------
configure_trackpad() {
  defaults_write com.apple.AppleMultitouchTrackpad Clicking bool true \
    "Trackpad: tap to click"
  defaults_write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking bool true \
    "Trackpad (Bluetooth): tap to click"
  defaults_write NSGlobalDomain com.apple.mouse.tapBehavior int 1 \
    "Mouse/trackpad: tap registers as click"
}

# ---------------------------------------------------------------------------
# configure_finder — navigation aids only. Deliberately NOT set (stock):
# hidden files (Cmd+Shift+. when needed), the status bar, desktop icons
# for external drives, and every warning dialog.
# ---------------------------------------------------------------------------
configure_finder() {
  defaults_write com.apple.finder ShowPathbar bool true \
    "Finder: show the path bar"
  defaults_write NSGlobalDomain AppleShowAllExtensions bool true \
    "Finder: show all file extensions"
  defaults_write com.apple.finder FXPreferredViewStyle string "Nlsv" \
    "Finder: default to list view"
  defaults_write com.apple.finder _FXSortFoldersFirst bool true \
    "Finder: keep folders on top when sorting"
  defaults_write com.apple.finder FXDefaultSearchScope string "SCcf" \
    "Finder: search the current folder by default"
  defaults_write com.apple.finder NewWindowTarget string "PfHm" \
    "Finder: new windows open in the home folder"
  defaults_write com.apple.desktopservices DSDontWriteNetworkStores bool true \
    "No .DS_Store on network volumes"
  defaults_write com.apple.desktopservices DSDontWriteUSBStores bool true \
    "No .DS_Store on USB volumes"
}

# ---------------------------------------------------------------------------
# configure_dock — icon size only. Position, auto-hide, magnification,
# minimize behavior, recents, and animations all stay stock.
# ---------------------------------------------------------------------------
configure_dock() {
  defaults_write com.apple.dock tilesize int 38 \
    "Dock: icon size 38px (~20%)"
}

# ---------------------------------------------------------------------------
# configure_screenshots — save into ~/Screenshots instead of the Desktop.
# Format and shadow stay stock (PNG, with shadow).
# ---------------------------------------------------------------------------
configure_screenshots() {
  ensure_dir "${MAC_SETUP_SCREENSHOT_DIR}"
  defaults_write com.apple.screencapture location string \
    "${MAC_SETUP_SCREENSHOT_DIR}" "Screenshots saved to ${MAC_SETUP_SCREENSHOT_DIR/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# configure_safari — developer mode and download safety.
# Safari's container may block `defaults` without Full Disk Access; failures
# here are downgraded to a single manual action.
# ---------------------------------------------------------------------------
configure_safari() {
  defaults_write NSGlobalDomain WebKitDeveloperExtras bool true \
    "Web views: enable inspector" || true

  # Safari's preferences live in a sandboxed container that `defaults` can
  # only write with Full Disk Access. Probe once; without access, record a
  # single manual action instead of failing three writes.
  if [[ "${DRY_RUN}" != "1" ]]; then
    if ! defaults write com.apple.Safari mac-setup-probe -bool true 2>/dev/null; then
      log_warn "Safari preferences are protected (terminal lacks Full Disk Access); skipping."
      report_manual "${MODULE}" "Safari defaults" \
        "https://support.apple.com/guide/mac-help/mchl211c911f/mac" \
        "Safari's sandboxed preferences cannot be written without Full Disk Access" \
        "Either grant your terminal Full Disk Access (System Settings → Privacy & Security → Full Disk Access) and re-run './install.sh --only macos', or enable 'Show features for web developers' manually in Safari → Settings → Advanced"
      return 0
    fi
    defaults delete com.apple.Safari mac-setup-probe 2>/dev/null || true
  fi

  defaults_write com.apple.Safari IncludeDevelopMenu bool true \
    "Safari: show the Develop menu" || true
  defaults_write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey bool true \
    "Safari: developer extras" || true
  defaults_write com.apple.Safari AutoOpenSafeDownloads bool false \
    "Safari: don't auto-open downloads" || true
}

# ---------------------------------------------------------------------------
# configure_panels — expanded save/print panels, save locally by default.
# ---------------------------------------------------------------------------
configure_panels() {
  defaults_write NSGlobalDomain NSNavPanelExpandedStateForSaveMode bool true \
    "Expand the save panel by default"
  defaults_write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 bool true \
    "Expand the save panel by default (2)"
  defaults_write NSGlobalDomain PMPrintingExpandedStateForPrint bool true \
    "Expand the print panel by default"
  defaults_write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud bool false \
    "Save new documents locally, not to iCloud"
}

# ---------------------------------------------------------------------------
# apply_changes — restart affected apps/services only when needed.
# ---------------------------------------------------------------------------
apply_changes() {
  if [[ "${DEFAULTS_CHANGED}" -eq 0 ]]; then
    log_skip "All macOS defaults already configured."
    report_skip "${MODULE}" "macOS defaults" "all values already set"
    return 0
  fi
  run killall Finder 2>/dev/null || true
  run killall Dock 2>/dev/null || true
  run killall SystemUIServer 2>/dev/null || true
  report_ok "${MODULE}" "macOS defaults" "applied (keyboard/trackpad changes need logout)"
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
    report_skip "${MODULE}" "macOS defaults" "disabled in settings"
    return 0
  fi

  # Stock-first cleanup always runs: it only *removes* legacy overrides, so it
  # is never an opt-out. Each additive tweak below is an optional suggestion,
  # ticked/unticked on the selection screen or pinned in config/settings.sh
  # (MAC_SETUP_PREF_*); unset means "apply" so a plain run still converges.
  remove_legacy_overrides
  pref_enabled KEYBOARD && configure_keyboard
  pref_enabled TRACKPAD && configure_trackpad
  pref_enabled FINDER && configure_finder
  pref_enabled DOCK && configure_dock
  pref_enabled SCREENSHOTS && configure_screenshots
  pref_enabled SAFARI && configure_safari
  pref_enabled PANELS && configure_panels
  apply_changes
}

main "$@"
