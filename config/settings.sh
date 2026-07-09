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
MAC_SETUP_GIT_NAME="${MAC_SETUP_GIT_NAME:-Pedro Brito}"
MAC_SETUP_GIT_EMAIL="${MAC_SETUP_GIT_EMAIL:-pedrohbrito@me.com}"
MAC_SETUP_GITHUB_USER="${MAC_SETUP_GITHUB_USER:-pedrobritx}"

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
