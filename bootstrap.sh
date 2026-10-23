#!/usr/bin/env bash
#
# bootstrap.sh — Zero-to-workstation entry point for a brand-new Mac.
#
# The ONE command:
#
#   curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
#
# What it does:
#   1. Sanity checks (macOS, not root).
#   2. Installs the Xcode Command Line Tools (needed for git).
#   3. Clones this repository to ~/Developer/mac-setup (or pulls if present).
#   4. Hands off to ./install.sh, which does everything else.
#
# It can also be run from an existing clone: it will skip the clone step.

set -euo pipefail

REPO_URL="https://github.com/pedrobritx/mac-setup.git"
CLONE_DIR="${MAC_SETUP_CLONE_DIR:-${HOME}/Developer/mac-setup}"

# Minimal logging — lib/ isn't available until the repo is cloned.
info() { printf '\033[34m•\033[0m %s\n' "$*"; }
success() { printf '\033[32m✓\033[0m %s\n' "$*"; }
error() { printf '\033[31m✗\033[0m %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# preflight — refuse to run in the wrong place.
# ---------------------------------------------------------------------------
preflight() {
  if [[ "$(uname -s)" != "Darwin" && "${MAC_SETUP_TEST:-0}" != "1" ]]; then
    error "bootstrap.sh only runs on macOS."
    exit 1
  fi
  if [[ "${EUID}" -eq 0 && "${MAC_SETUP_TEST:-0}" != "1" ]]; then
    error "Do not run as root."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# install_clt — Xcode Command Line Tools, required before git/clone works.
# Uses the GUI prompt as the reliable path on a truly fresh machine.
# ---------------------------------------------------------------------------
install_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    success "Xcode Command Line Tools present."
    return 0
  fi
  info "Installing Xcode Command Line Tools (a dialog will appear)..."
  xcode-select --install >/dev/null 2>&1 || true
  info "Waiting for the installation to complete — approve the dialog."
  until xcode-select -p >/dev/null 2>&1; do
    sleep 15
  done
  success "Xcode Command Line Tools installed."
}

# ---------------------------------------------------------------------------
# clone_repo — clone (or update) the repository.
# ---------------------------------------------------------------------------
clone_repo() {
  # Already inside a clone? (bootstrap run from the repo itself)
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || echo "")"
  if [[ -n "${script_dir}" && -f "${script_dir}/install.sh" ]]; then
    CLONE_DIR="${script_dir}"
    success "Running from existing clone: ${CLONE_DIR}"
    return 0
  fi

  if [[ -d "${CLONE_DIR}/.git" ]]; then
    info "Repository exists at ${CLONE_DIR}; pulling latest..."
    git -C "${CLONE_DIR}" pull --ff-only || true
    return 0
  fi

  info "Cloning ${REPO_URL} to ${CLONE_DIR}..."
  mkdir -p "$(dirname "${CLONE_DIR}")"
  git clone "${REPO_URL}" "${CLONE_DIR}"
  success "Cloned."
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  printf '\n\033[1mmac-setup bootstrap\033[0m — turning this Mac into a workstation.\n\n'
  preflight
  install_clt
  clone_repo

  cd "${CLONE_DIR}"
  if [[ "${1:-}" == "--web" ]]; then
    shift
    info "Opening the guided browser setup..."
    exec ./web.sh "$@"
  fi
  info "Handing off to install.sh..."
  exec ./install.sh "$@"
}

main "$@"
