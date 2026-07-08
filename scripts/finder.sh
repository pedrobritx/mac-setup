#!/usr/bin/env bash
#
# scripts/finder.sh — Finder defaults.
#
# Hidden files, extensions, path/status bars, folders-first sorting, list
# view, search scope, and .DS_Store hygiene on network volumes.
# Finder is restarted only when a value actually changed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="finder"
DEFAULTS_CHANGED=0

# ---------------------------------------------------------------------------
# configure_visibility — show what the system hides by default.
# ---------------------------------------------------------------------------
configure_visibility() {
  defaults_write com.apple.finder AppleShowAllFiles bool true \
    "Finder: show hidden files"
  defaults_write NSGlobalDomain AppleShowAllExtensions bool true \
    "Finder: show all file extensions"
  defaults_write com.apple.finder ShowPathbar bool true \
    "Finder: show the path bar"
  defaults_write com.apple.finder ShowStatusBar bool true \
    "Finder: show the status bar"
  defaults_write com.apple.finder ShowExternalHardDrivesOnDesktop bool true \
    "Finder: show external drives on the desktop"
}

# ---------------------------------------------------------------------------
# configure_behavior — list view, folders first, sane search & warnings.
# ---------------------------------------------------------------------------
configure_behavior() {
  defaults_write com.apple.finder FXPreferredViewStyle string "Nlsv" \
    "Finder: default to list view"
  defaults_write com.apple.finder _FXSortFoldersFirst bool true \
    "Finder: keep folders on top when sorting"
  defaults_write com.apple.finder FXDefaultSearchScope string "SCcf" \
    "Finder: search the current folder by default"
  defaults_write com.apple.finder FXEnableExtensionChangeWarning bool false \
    "Finder: no warning when changing an extension"
  defaults_write com.apple.finder NewWindowTarget string "PfHm" \
    "Finder: new windows open in the home folder"
  defaults_write com.apple.finder ShowRecentTags bool false \
    "Finder: hide recent tags in the sidebar"
}

# ---------------------------------------------------------------------------
# configure_ds_store — stop littering network/USB volumes with .DS_Store.
# ---------------------------------------------------------------------------
configure_ds_store() {
  defaults_write com.apple.desktopservices DSDontWriteNetworkStores bool true \
    "No .DS_Store on network volumes"
  defaults_write com.apple.desktopservices DSDontWriteUSBStores bool true \
    "No .DS_Store on USB volumes"
}

# ---------------------------------------------------------------------------
# apply_changes — restart Finder only when something changed.
# ---------------------------------------------------------------------------
apply_changes() {
  if [[ "${DEFAULTS_CHANGED}" -eq 0 ]]; then
    log_skip "All Finder defaults already configured."
    report_skip "${MODULE}" "Finder defaults" "all values already set"
    return 0
  fi
  run killall Finder 2>/dev/null || true
  report_ok "${MODULE}" "Finder defaults" "applied and Finder restarted"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if [[ "${MAC_SETUP_ENABLE_MACOS_DEFAULTS}" != "1" ]]; then
    log_skip "macOS defaults disabled in config/settings.sh."
    report_skip "${MODULE}" "Finder defaults" "disabled in settings"
    return 0
  fi

  configure_visibility
  configure_behavior
  configure_ds_store
  apply_changes
}

main "$@"
