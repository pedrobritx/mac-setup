#!/usr/bin/env bash
#
# scripts/docker.sh — Docker Desktop.
#
#   * Docker Desktop is installed by the Brewfile cask (docker-desktop);
#     this module verifies it and finishes the setup.
#   * Verifies virtualization support (Hypervisor.framework).
#   * Starts Docker Desktop, waits for the daemon, and runs hello-world.
#
# Docker Compose and Buildx ship inside Docker Desktop — no separate
# formulae needed (documented in docs/ARCHITECTURE.md).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="docker"
readonly DAEMON_WAIT_SECONDS=120

# ---------------------------------------------------------------------------
# verify_virtualization — Hypervisor.framework support check.
# All Apple Silicon and virtually all Intel Macs since 2010 support it.
# ---------------------------------------------------------------------------
verify_virtualization() {
  if [[ "${DRY_RUN}" == "1" && "$(uname -s)" != "Darwin" ]]; then
    log_dry "sysctl kern.hv_support"
    return 0
  fi

  local hv
  hv="$(sysctl -n kern.hv_support 2>/dev/null || echo 0)"
  if [[ "${hv}" == "1" ]]; then
    log_success "Virtualization supported (Hypervisor.framework)."
    report_ok "${MODULE}" "virtualization" "kern.hv_support=1"
  else
    report_fail "${MODULE}" "virtualization" "kern.hv_support=0 — Docker Desktop cannot run on this Mac"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# ensure_installed — confirm the Docker Desktop app is present.
# ---------------------------------------------------------------------------
ensure_installed() {
  if app_installed "Docker" || app_installed "Docker Desktop"; then
    log_skip "Docker Desktop installed."
    report_skip "${MODULE}" "Docker Desktop" "already installed"
    return 0
  fi
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "brew install --cask docker-desktop"
    return 0
  fi
  log_info "Docker Desktop missing; installing via Homebrew..."
  if run brew install --cask docker-desktop; then
    report_ok "${MODULE}" "Docker Desktop" "installed"
  else
    report_fail "${MODULE}" "Docker Desktop" "cask install failed"
    return 1
  fi
}

# ---------------------------------------------------------------------------
# wait_for_daemon — open Docker Desktop and poll until the engine responds.
# First launch requires accepting the Docker Subscription Service Agreement,
# so a timeout here becomes a manual-actions entry rather than a failure.
# ---------------------------------------------------------------------------
wait_for_daemon() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "open -a Docker && wait for 'docker info'"
    return 0
  fi

  if docker info >/dev/null 2>&1; then
    log_skip "Docker daemon already running."
    return 0
  fi

  log_info "Starting Docker Desktop (first launch may show a license prompt)..."
  open -a "Docker" 2>/dev/null || open -a "Docker Desktop" 2>/dev/null || {
    report_fail "${MODULE}" "Docker daemon" "could not launch the Docker Desktop app"
    return 1
  }

  local waited=0
  until docker info >/dev/null 2>&1; do
    if ((waited >= DAEMON_WAIT_SECONDS)); then
      report_manual "${MODULE}" "Docker first launch" \
        "https://docs.docker.com/desktop/setup/install/mac-install/" \
        "first launch requires accepting the service agreement in the GUI" \
        "Open Docker Desktop, accept the agreement, wait for 'Engine running', then run: ./verify.sh"
      return 1
    fi
    sleep 5
    waited=$((waited + 5))
    log_debug "waiting for docker daemon (${waited}s)"
  done
  log_success "Docker daemon is running."
}

# ---------------------------------------------------------------------------
# run_hello_world — end-to-end engine check.
# ---------------------------------------------------------------------------
run_hello_world() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "docker run --rm hello-world"
    return 0
  fi

  docker info >/dev/null 2>&1 || return 0

  log_info "Running hello-world container..."
  if run_quiet docker run --rm hello-world; then
    log_success "hello-world ran successfully."
    report_ok "${MODULE}" "hello-world" "container ran successfully"
  else
    report_fail "${MODULE}" "hello-world" "container failed — check 'docker run hello-world' output"
  fi

  if docker compose version >/dev/null 2>&1; then
    report_ok "${MODULE}" "docker compose" "$(docker compose version --short 2>/dev/null)"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  verify_virtualization || return 0
  ensure_installed || return 0
  wait_for_daemon || return 0
  run_hello_world
}

main "$@"
