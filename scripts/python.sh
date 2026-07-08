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
    report_fail "${MODULE}" "uv" "not installed — run the brew module first"
    return 1
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
    report_fail "${MODULE}" "pipx" "not installed — run the brew module first"
    return 1
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
