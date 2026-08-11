#!/usr/bin/env bash
#
# scripts/python.sh — Python toolchain.
#
#   * uv manages Python versions, virtualenvs, and packages. It replaces
#     pyenv + pip + virtualenv with one fast (Rust) tool and never touches
#     the system Python.
#   * pipx installs Python CLI tools into isolated environments.
#
# Both come from the Brewfile; this module installs the interpreter and
# wires up PATHs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="python"

# ---------------------------------------------------------------------------
# install_python — install the configured CPython through uv.
# ---------------------------------------------------------------------------
install_python() {
  if ! has_command uv; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "uv python install ${MAC_SETUP_PYTHON_VERSION}"
      return 0
    fi
    if ! brewfile_formula_selected uv; then
      log_skip "uv unticked in the Brewfile selection — skipping the Python toolchain."
      report_skip "${MODULE}" "Python" "uv unticked in Brewfile selection"
      return 0
    fi
    # Self-heal: the brew module may have failed partway; install uv here.
    if ensure_brew_formula uv && has_command uv; then
      report_ok "${MODULE}" "uv" "installed via Homebrew"
    else
      report_fail "${MODULE}" "uv" "not installed and brew install failed"
      return 1
    fi
  fi

  local want="${MAC_SETUP_PYTHON_VERSION}"
  if uv python list --only-installed 2>/dev/null | grep -q "cpython-${want}"; then
    log_skip "Python ${want} already installed via uv."
    report_skip "${MODULE}" "Python ${want}" "already installed via uv"
    return 0
  fi

  log_info "Installing Python ${want} via uv..."
  if run_retry 3 uv python install "${want}"; then
    log_success "Python ${want} installed."
    report_ok "${MODULE}" "Python ${want}" "installed via uv"
  else
    report_fail "${MODULE}" "Python ${want}" "uv python install failed"
  fi
}

# ---------------------------------------------------------------------------
# configure_pipx — make sure pipx-installed CLIs land on PATH.
# ---------------------------------------------------------------------------
configure_pipx() {
  if ! has_command pipx; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "pipx ensurepath"
      return 0
    fi
    if ! brewfile_formula_selected pipx; then
      log_skip "pipx unticked in the Brewfile selection."
      report_skip "${MODULE}" "pipx" "unticked in Brewfile selection"
      return 0
    fi
    # Self-heal: the brew module may have failed partway; install pipx here.
    if ! ensure_brew_formula pipx || ! has_command pipx; then
      report_fail "${MODULE}" "pipx" "not installed and brew install failed"
      return 1
    fi
    report_ok "${MODULE}" "pipx" "installed via Homebrew"
  fi

  run_quiet pipx ensurepath 2>/dev/null || true
  log_success "pipx ready (install CLI tools with: pipx install <tool>)."
  report_ok "${MODULE}" "pipx" "PATH configured"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  install_python
  configure_pipx
}

main "$@"
