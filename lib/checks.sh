#!/usr/bin/env bash
#
# lib/checks.sh — Idempotency predicates.
#
# Every install/configure action in this repository is guarded by one of
# these checks so that re-running mac-setup is always safe: anything already
# satisfied is detected and skipped.
#
# All functions return 0 (true) / non-zero (false) and print nothing, so they
# compose cleanly in `if` statements.

if [[ -n "${_MAC_SETUP_CHECKS_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_CHECKS_LOADED=1

# has_command <name> — true when an executable is on PATH.
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# brew_formula_installed <formula> — true when a Homebrew formula is installed.
brew_formula_installed() {
  has_command brew && brew list --formula --versions "$1" >/dev/null 2>&1
}

# brew_cask_installed <cask> — true when a Homebrew cask is installed.
brew_cask_installed() {
  has_command brew && brew list --cask --versions "$1" >/dev/null 2>&1
}

# brew_tap_installed <tap> — true when a tap is already tapped.
brew_tap_installed() {
  has_command brew && brew tap | grep -qx "$1"
}

# app_installed <App Name> — true when "<App Name>.app" exists in any of the
# standard application directories. Catches apps installed outside Homebrew
# (Mac App Store, DMG installs) so we never double-install.
app_installed() {
  local app="$1"
  [[ -d "/Applications/${app}.app" ]] ||
    [[ -d "${HOME}/Applications/${app}.app" ]] ||
    [[ -d "/System/Applications/${app}.app" ]]
}

# cask_app_name <cask> — print the .app bundle name a cask installs, for the
# duplicate-copy guard (see scripts/brew.sh): when the app already exists —
# from the Mac App Store or a manual install — the cask is skipped so a
# second copy is never created. Prints nothing for unknown casks (no guard).
cask_app_name() {
  case "$1" in
    visual-studio-code) echo "Visual Studio Code" ;;
    antigravity) echo "Antigravity" ;;
    docker-desktop) echo "Docker" ;;
    postman) echo "Postman" ;;
    figma) echo "Figma" ;;
    sf-symbols) echo "SF Symbols" ;;
    github) echo "GitHub Desktop" ;;
    blender) echo "Blender" ;;
    inkscape) echo "Inkscape" ;;
    1password) echo "1Password" ;;
    bettertouchtool) echo "BetterTouchTool" ;;
    keyboardcleantool) echo "KeyboardCleanTool" ;;
    anydesk) echo "AnyDesk" ;;
    teamviewer) echo "TeamViewer" ;;
    zoom) echo "zoom.us" ;;
    dropbox) echo "Dropbox" ;;
    obs) echo "OBS" ;;
    transmission) echo "Transmission" ;;
    google-chrome) echo "Google Chrome" ;;
    chatgpt) echo "ChatGPT" ;;
    claude) echo "Claude" ;;
    notion) echo "Notion" ;;
    obsidian) echo "Obsidian" ;;
    discord) echo "Discord" ;;
    google-drive) echo "Google Drive" ;;
    libreoffice) echo "LibreOffice" ;;
    appcleaner) echo "AppCleaner" ;;
    caffeine) echo "Caffeine" ;;
    daisydisk) echo "DaisyDisk" ;;
    logi-options+) echo "logioptionsplus" ;;
    the-unarchiver) echo "The Unarchiver" ;;
    microsoft-teams) echo "Microsoft Teams" ;;
    whatsapp) echo "WhatsApp" ;;
    vlc) echo "VLC" ;;
    steam) echo "Steam" ;;
    stremio) echo "Stremio" ;;
    *) echo "" ;;
  esac
}

# brewfile_formula_selected <formula> — true when `brew "<formula>"` is
# present in the active Brewfile ($MAC_SETUP_BREWFILE). On a plain/CI run
# that's the full repo Brewfile (always true); after the interactive picker
# it's the filtered "active" Brewfile, so an unticked formula reads false.
# Used to stop self-heal installs (node/python modules) from reinstalling
# something the user explicitly unticked.
brewfile_formula_selected() {
  grep -qE "^brew \"$1\"" "${MAC_SETUP_BREWFILE}" 2>/dev/null
}

# mas_app_installed <app_id> — true when a Mac App Store app id is installed.
mas_app_installed() {
  has_command mas && mas list 2>/dev/null | awk '{print $1}' | grep -qx "$1"
}

# mas_signed_in — true when the machine can install from the App Store.
# `mas account` is unreliable on modern macOS, so treat "any previous mas
# install exists" or a successful account query as signed in.
mas_signed_in() {
  has_command mas || return 1
  mas account >/dev/null 2>&1 && return 0
  [[ -n "$(mas list 2>/dev/null)" ]]
}

# font_installed <pattern> — true when a font file matching the glob pattern
# exists in the user or system font directories.
font_installed() {
  local pattern="$1" dir
  for dir in "${HOME}/Library/Fonts" "/Library/Fonts"; do
    if compgen -G "${dir}/${pattern}" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

# xcode_clt_installed — true when the Xcode Command Line Tools are present.
xcode_clt_installed() {
  [[ "${MAC_SETUP_TEST:-0}" == "1" ]] && return 0
  xcode-select -p >/dev/null 2>&1
}

# file_is_linked_to <target> <source> — true when target is a symlink that
# already points at source.
file_is_linked_to() {
  [[ -L "$1" && "$(readlink "$1")" == "$2" ]]
}

# default_equals <domain> <key> <expected> — true when a macOS `defaults`
# value already matches. Used to make `defaults write` idempotent and to
# avoid needlessly restarting Dock/Finder.
default_equals() {
  local domain="$1" key="$2" expected="$3" current
  current="$(defaults read "${domain}" "${key}" 2>/dev/null)" || return 1
  [[ "${current}" == "${expected}" ]]
}

# git_config_equals <key> <expected> — true when a global git config value
# already matches.
git_config_equals() {
  local key="$1" expected="$2" current
  current="$(git config --global --get "${key}" 2>/dev/null)" || return 1
  [[ "${current}" == "${expected}" ]]
}

# vscode_extension_installed <id> — true when a VS Code extension is
# installed (case-insensitive, as `code` normalizes ids to lowercase).
vscode_extension_installed() {
  has_command code || return 1
  code --list-extensions 2>/dev/null |
    tr '[:upper:]' '[:lower:]' |
    grep -qx "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
}
