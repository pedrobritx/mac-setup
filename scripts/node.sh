#!/usr/bin/env bash
#
# scripts/node.sh — Node.js toolchain.
#
#   * Node.js itself is managed by fnm (installed from the Brewfile) so
#     versions can be switched per-project via .nvmrc/.node-version.
#   * pnpm and bun come from the Brewfile.
#   * corepack is enabled so per-project packageManager fields work.
#
# Why fnm instead of `brew install node`: Homebrew's node is a single global
# version that major-bumps under you; fnm is fast (Rust), respects
# per-project version files, and keeps versions out of brew's way.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="node"

# ---------------------------------------------------------------------------
# install_node — install the configured Node version through fnm and set it
# as the default.
# ---------------------------------------------------------------------------
install_node() {
  if ! has_command fnm; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "fnm install --lts && fnm default lts-latest"
      return 0
    fi
    report_fail "${MODULE}" "fnm" "not installed — run the brew module first"
    return 1
  fi

  # Make fnm's shims visible in this non-interactive shell.
  eval "$(fnm env 2>/dev/null)" || true

  local want="${MAC_SETUP_NODE_VERSION}"
  if fnm list 2>/dev/null | grep -q "default" && has_command node; then
    log_skip "Node.js already installed via fnm ($(node --version 2>/dev/null))."
    report_skip "${MODULE}" "Node.js" "already installed ($(node --version 2>/dev/null))"
    return 0
  fi

  log_info "Installing Node.js (${want}) via fnm..."
  if [[ "${want}" == lts* ]]; then
    run_retry 3 fnm install --lts
  else
    run_retry 3 fnm install "${want}"
  fi
  run fnm default "${want}" || run fnm default lts-latest || true
  eval "$(fnm env 2>/dev/null)" || true
  run fnm use "${want}" 2>/dev/null || true

  if has_command node || [[ "${DRY_RUN}" == "1" ]]; then
    log_success "Node.js ready$(has_command node && echo " ($(node --version))")."
    report_ok "${MODULE}" "Node.js" "installed via fnm"
  else
    report_fail "${MODULE}" "Node.js" "fnm install did not produce a usable node"
  fi
}

# ---------------------------------------------------------------------------
# enable_corepack — let per-project "packageManager" fields work.
# ---------------------------------------------------------------------------
enable_corepack() {
  has_command corepack || {
    log_debug "corepack unavailable"
    return 0
  }
  if run_quiet corepack enable 2>/dev/null; then
    log_success "corepack enabled."
  else
    log_debug "corepack enable skipped"
  fi
}

# ---------------------------------------------------------------------------
# verify_package_managers — pnpm and bun come from the Brewfile.
# ---------------------------------------------------------------------------
verify_package_managers() {
  local pm
  for pm in pnpm bun; do
    if has_command "${pm}"; then
      log_success "${pm} $(${pm} --version 2>/dev/null) available."
      report_ok "${MODULE}" "${pm}" "version $(${pm} --version 2>/dev/null)"
    elif [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "${pm} missing (dry-run)"
    else
      report_fail "${MODULE}" "${pm}" "not found — check the brew module output"
    fi
  done
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  install_node
  enable_corepack
  verify_package_managers
}

main "$@"
