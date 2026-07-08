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
