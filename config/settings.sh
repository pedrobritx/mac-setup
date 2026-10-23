#!/usr/bin/env bash
#
# config/settings.sh — User-editable configuration.
#
# This is the ONE file you should edit to personalize mac-setup.
# Every value can also be overridden per-run via environment variables
# (env wins over this file), e.g.:
#
#   MAC_SETUP_GIT_EMAIL="work@example.com" ./install.sh
#
# Application/package selection lives in the Brewfile, not here.

if [[ -n "${_MAC_SETUP_SETTINGS_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_SETTINGS_LOADED=1

# ---------------------------------------------------------------------------
# Identity — used by scripts/git.sh and scripts/ssh.sh.
# Leave empty to be prompted interactively during install.
# ---------------------------------------------------------------------------
MAC_SETUP_GIT_NAME="${MAC_SETUP_GIT_NAME:-}"
MAC_SETUP_GIT_EMAIL="${MAC_SETUP_GIT_EMAIL:-}"
MAC_SETUP_GITHUB_USER="${MAC_SETUP_GITHUB_USER:-}"

# Default branch name for new repositories.
MAC_SETUP_GIT_DEFAULT_BRANCH="${MAC_SETUP_GIT_DEFAULT_BRANCH:-main}"

# Sign commits with the SSH key (1) or leave signing unconfigured (0).
MAC_SETUP_GIT_SSH_SIGNING="${MAC_SETUP_GIT_SSH_SIGNING:-1}"

export MAC_SETUP_GIT_NAME MAC_SETUP_GIT_EMAIL MAC_SETUP_GITHUB_USER \
  MAC_SETUP_GIT_DEFAULT_BRANCH MAC_SETUP_GIT_SSH_SIGNING

# ---------------------------------------------------------------------------
# SSH — key type and file used by scripts/ssh.sh. Existing keys are NEVER
# overwritten regardless of these values.
# ---------------------------------------------------------------------------
MAC_SETUP_SSH_KEY_TYPE="${MAC_SETUP_SSH_KEY_TYPE:-ed25519}"
MAC_SETUP_SSH_KEY_FILE="${MAC_SETUP_SSH_KEY_FILE:-${HOME}/.ssh/id_ed25519}"
export MAC_SETUP_SSH_KEY_TYPE MAC_SETUP_SSH_KEY_FILE

# ---------------------------------------------------------------------------
# Directory layout — created by scripts/directories.sh. Paths are relative
# to $HOME. Add or remove entries freely; creation is idempotent.
# ---------------------------------------------------------------------------
MAC_SETUP_DIRECTORIES=(
  "Developer"
  "Developer/Personal"
  "Developer/Clients"
  "Developer/Archive"
  "Developer/Learning"
  "Developer/Experiments"
  "Developer/OpenSource"
  "Downloads/Installers"
  "Workspace"
  "Screenshots"
  "Projects"
)
export MAC_SETUP_DIRECTORIES

# Where macOS saves screenshots (configured by scripts/macos.sh).
MAC_SETUP_SCREENSHOT_DIR="${MAC_SETUP_SCREENSHOT_DIR:-${HOME}/Screenshots}"
export MAC_SETUP_SCREENSHOT_DIR

# ---------------------------------------------------------------------------
# Node.js — version installed through fnm by scripts/node.sh.
# "lts-latest" tracks the current LTS line.
# ---------------------------------------------------------------------------
MAC_SETUP_NODE_VERSION="${MAC_SETUP_NODE_VERSION:-lts-latest}"
export MAC_SETUP_NODE_VERSION

# ---------------------------------------------------------------------------
# Python — versions installed through uv by scripts/python.sh.
# ---------------------------------------------------------------------------
MAC_SETUP_PYTHON_VERSION="${MAC_SETUP_PYTHON_VERSION:-3.13}"
export MAC_SETUP_PYTHON_VERSION

# ---------------------------------------------------------------------------
# Module toggles — set to 0 to exclude a module from full installs.
# (Equivalent to passing --skip <module> every time.)
# ---------------------------------------------------------------------------
MAC_SETUP_ENABLE_MACOS_DEFAULTS="${MAC_SETUP_ENABLE_MACOS_DEFAULTS:-1}"
MAC_SETUP_ENABLE_SECURITY="${MAC_SETUP_ENABLE_SECURITY:-1}"
export MAC_SETUP_ENABLE_MACOS_DEFAULTS MAC_SETUP_ENABLE_SECURITY

# ===========================================================================
# Suggested preferences — per-category tweaks (macOS defaults + security).
#
# Nothing here is forced. On an interactive install the selection screen lists
# each of these as a ticked suggestion you can untick; those choices are what
# actually drive the run. Set a value here to PIN a category regardless of the
# picker (handy for `--only`, `--yes`, or fully unattended runs):
#
#     (blank / 1 / yes / on)  → apply this suggestion   ← default when unset
#     0 / no / off            → skip this suggestion
#
# Override per run from the environment too, e.g.:
#     MAC_SETUP_PREF_SAFARI=no ./install.sh --only macos
#
# Note: window management, Mission Control, Dock magnification and animations
# are deliberately NOT offered — they stay stock (see scripts/macos.sh), and
# legacy overrides are always removed regardless of these toggles.
# ---------------------------------------------------------------------------
# macOS defaults (scripts/macos.sh)
MAC_SETUP_PREF_KEYBOARD="${MAC_SETUP_PREF_KEYBOARD:-}"       # fast key repeat, no autocorrect
MAC_SETUP_PREF_TRACKPAD="${MAC_SETUP_PREF_TRACKPAD:-}"       # tap to click
MAC_SETUP_PREF_FINDER="${MAC_SETUP_PREF_FINDER:-}"           # path bar, extensions, list view, .DS_Store hygiene
MAC_SETUP_PREF_DOCK="${MAC_SETUP_PREF_DOCK:-}"               # Dock icon size (~20%)
MAC_SETUP_PREF_SCREENSHOTS="${MAC_SETUP_PREF_SCREENSHOTS:-}" # save screenshots to ~/Screenshots
MAC_SETUP_PREF_SAFARI="${MAC_SETUP_PREF_SAFARI:-}"           # Safari Develop menu + web inspector
MAC_SETUP_PREF_PANELS="${MAC_SETUP_PREF_PANELS:-}"           # expanded save/print panels, local saves
# Security (scripts/security.sh)
MAC_SETUP_PREF_FIREWALL="${MAC_SETUP_PREF_FIREWALL:-}"         # application firewall on
MAC_SETUP_PREF_TOUCHID_SUDO="${MAC_SETUP_PREF_TOUCHID_SUDO:-}" # Touch ID for sudo
MAC_SETUP_PREF_SCREEN_LOCK="${MAC_SETUP_PREF_SCREEN_LOCK:-}"   # password immediately after sleep
MAC_SETUP_PREF_FULL_XCODE="${MAC_SETUP_PREF_FULL_XCODE:-1}"    # full IDE remains optional in the picker
MAC_SETUP_PREF_OHMYZSH="${MAC_SETUP_PREF_OHMYZSH:-0}"          # standalone Starship is the default

export MAC_SETUP_PREF_KEYBOARD MAC_SETUP_PREF_TRACKPAD MAC_SETUP_PREF_FINDER \
  MAC_SETUP_PREF_DOCK MAC_SETUP_PREF_SCREENSHOTS MAC_SETUP_PREF_SAFARI \
  MAC_SETUP_PREF_PANELS MAC_SETUP_PREF_FIREWALL MAC_SETUP_PREF_TOUCHID_SUDO \
  MAC_SETUP_PREF_SCREEN_LOCK MAC_SETUP_PREF_FULL_XCODE MAC_SETUP_PREF_OHMYZSH
