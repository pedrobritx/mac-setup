#!/usr/bin/env bash
#
# lib/common.sh — Core foundation for every mac-setup script.
#
# Responsibilities:
#   * Resolve repository paths and state directories.
#   * Detect platform (macOS version, architecture, Homebrew prefix).
#   * Load the rest of the library (log, run, checks, report) and user config.
#   * Provide small, widely used guards (require_macos, require_not_root).
#
# Usage (from any script in this repository):
#   source "${SCRIPT_DIR}/../lib/common.sh"
#
# This file is safe to source multiple times.

# ---------------------------------------------------------------------------
# Double-source guard
# ---------------------------------------------------------------------------
if [[ -n "${_MAC_SETUP_COMMON_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_COMMON_LOADED=1

# ---------------------------------------------------------------------------
# Repository layout
# ---------------------------------------------------------------------------

# Absolute path to the repository root (parent of lib/).
if [[ -z "${MAC_SETUP_ROOT:-}" ]]; then
  MAC_SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export MAC_SETUP_ROOT

MAC_SETUP_LIB_DIR="${MAC_SETUP_ROOT}/lib"
MAC_SETUP_SCRIPTS_DIR="${MAC_SETUP_ROOT}/scripts"
MAC_SETUP_DOTFILES_DIR="${MAC_SETUP_ROOT}/dotfiles"
MAC_SETUP_CONFIG_DIR="${MAC_SETUP_ROOT}/config"
# The repository Brewfile by default. install.sh points this at a generated
# "active" Brewfile (the user's picker selection) for the modules it spawns,
# so honor an already-exported value.
MAC_SETUP_BREWFILE="${MAC_SETUP_BREWFILE:-${MAC_SETUP_ROOT}/Brewfile}"
export MAC_SETUP_LIB_DIR MAC_SETUP_SCRIPTS_DIR MAC_SETUP_DOTFILES_DIR \
  MAC_SETUP_CONFIG_DIR MAC_SETUP_BREWFILE

# ---------------------------------------------------------------------------
# State, logs, reports (XDG-style, outside the repository)
# ---------------------------------------------------------------------------

MAC_SETUP_STATE_DIR="${MAC_SETUP_STATE_DIR:-${HOME}/.local/state/mac-setup}"
MAC_SETUP_LOG_DIR="${MAC_SETUP_STATE_DIR}/logs"
MAC_SETUP_REPORT_DIR="${MAC_SETUP_STATE_DIR}/reports"
MAC_SETUP_BACKUP_DIR="${MAC_SETUP_STATE_DIR}/backups"
MAC_SETUP_MANIFEST_DIR="${MAC_SETUP_STATE_DIR}/manifest"
export MAC_SETUP_STATE_DIR MAC_SETUP_LOG_DIR MAC_SETUP_REPORT_DIR \
  MAC_SETUP_BACKUP_DIR MAC_SETUP_MANIFEST_DIR

# A run id shared by the orchestrator and every module it spawns, so a single
# `install.sh` invocation produces one log file and one set of reports.
MAC_SETUP_RUN_ID="${MAC_SETUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
export MAC_SETUP_RUN_ID

# Raw machine-readable event stream (TSV) that lib/report.sh appends to and
# renders from. Shared across module subprocesses via the environment.
MAC_SETUP_REPORT_RAW="${MAC_SETUP_REPORT_RAW:-${MAC_SETUP_REPORT_DIR}/${MAC_SETUP_RUN_ID}.tsv}"
export MAC_SETUP_REPORT_RAW

# Manifest of symlinks created by this tool; consumed by uninstall.sh.
MAC_SETUP_LINK_MANIFEST="${MAC_SETUP_MANIFEST_DIR}/symlinks.tsv"
export MAC_SETUP_LINK_MANIFEST

# Runtime flags (exported by install.sh; default off when a module is run
# standalone without them).
DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"
export DRY_RUN VERBOSE

# ---------------------------------------------------------------------------
# ensure_state_dirs — create the state/log/report/backup directories.
# Always real (never dry-run): reports and logs must work even in dry-run.
# ---------------------------------------------------------------------------
ensure_state_dirs() {
  mkdir -p "${MAC_SETUP_STATE_DIR}" "${MAC_SETUP_LOG_DIR}" \
    "${MAC_SETUP_REPORT_DIR}" "${MAC_SETUP_BACKUP_DIR}" \
    "${MAC_SETUP_MANIFEST_DIR}"
}

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

# is_macos — succeed when running on macOS (or when MAC_SETUP_TEST=1, which
# lets CI exercise the orchestration path on Linux in dry-run mode).
is_macos() {
  [[ "$(uname -s)" == "Darwin" || "${MAC_SETUP_TEST:-0}" == "1" ]]
}

# is_apple_silicon — succeed on arm64 Macs.
is_apple_silicon() {
  [[ "$(uname -m)" == "arm64" ]]
}

# macos_version — print the macOS product version (e.g. "15.5"), or "unknown".
macos_version() {
  if command -v sw_vers >/dev/null 2>&1; then
    sw_vers -productVersion
  else
    echo "unknown"
  fi
}

# brew_prefix — print the expected Homebrew prefix for this machine.
# Works even before Homebrew is installed.
brew_prefix() {
  if is_apple_silicon; then
    echo "/opt/homebrew"
  else
    echo "/usr/local"
  fi
}

# ensure_brew_in_path — make `brew` resolvable in non-login shells (e.g. when
# bootstrap.sh just installed it and PATH has not been reloaded yet).
ensure_brew_in_path() {
  if ! command -v brew >/dev/null 2>&1; then
    local prefix
    prefix="$(brew_prefix)"
    if [[ -x "${prefix}/bin/brew" ]]; then
      eval "$("${prefix}/bin/brew" shellenv)"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

# require_macos — abort unless running on macOS (or in test mode).
require_macos() {
  if ! is_macos; then
    log_error "This script only runs on macOS (detected: $(uname -s))."
    exit 1
  fi
}

# require_not_root — abort when run as root. Homebrew refuses root, and
# everything here operates on the current user's environment.
require_not_root() {
  if [[ "${EUID}" -eq 0 && "${MAC_SETUP_TEST:-0}" != "1" ]]; then
    log_error "Do not run mac-setup as root. Run it as your normal user;"
    log_error "individual steps will ask for sudo when they need it."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Load the rest of the library and the user configuration
# ---------------------------------------------------------------------------
# shellcheck source=lib/log.sh
source "${MAC_SETUP_LIB_DIR}/log.sh"
# shellcheck source=lib/run.sh
source "${MAC_SETUP_LIB_DIR}/run.sh"
# shellcheck source=lib/checks.sh
source "${MAC_SETUP_LIB_DIR}/checks.sh"
# shellcheck source=lib/report.sh
source "${MAC_SETUP_LIB_DIR}/report.sh"
# shellcheck source=lib/progress.sh
source "${MAC_SETUP_LIB_DIR}/progress.sh"
# shellcheck source=config/settings.sh
source "${MAC_SETUP_CONFIG_DIR}/settings.sh"
