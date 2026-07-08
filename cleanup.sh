#!/usr/bin/env bash
#
# cleanup.sh — Reclaim disk space and prune mac-setup's own state.
#
#   * brew cleanup (downloads cache, old versions) + autoremove
#   * prune mac-setup logs/reports older than 30 days
#   * prune mac-setup backups older than 90 days (they exist for recovery,
#     not forever)
#   * optional: docker system prune (asks first — it deletes images)
#
# Never touches user files.
#
# Usage: ./cleanup.sh [--dry-run] [--verbose] [--yes]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

readonly LOG_RETENTION_DAYS=30
readonly BACKUP_RETENTION_DAYS=90

# ---------------------------------------------------------------------------
# cleanup_brew — Homebrew caches, dead symlinks, orphaned dependencies.
# ---------------------------------------------------------------------------
cleanup_brew() {
  ensure_brew_in_path
  has_command brew || {
    log_debug "brew not installed"
    return 0
  }
  log_step "Homebrew cleanup"
  run brew cleanup -s
  run brew autoremove || true
}

# ---------------------------------------------------------------------------
# cleanup_state — prune old mac-setup logs, reports, and backups.
# ---------------------------------------------------------------------------
cleanup_state() {
  log_step "mac-setup state"
  local pruned

  for dir in "${MAC_SETUP_LOG_DIR}" "${MAC_SETUP_REPORT_DIR}"; do
    [[ -d "${dir}" ]] || continue
    pruned="$(find "${dir}" -type f -mtime "+${LOG_RETENTION_DAYS}" | wc -l | tr -d ' ')"
    if [[ "${pruned}" -gt 0 ]]; then
      log_info "Pruning ${pruned} file(s) older than ${LOG_RETENTION_DAYS} days from ${dir/#${HOME}/~}"
      if [[ "${DRY_RUN}" == "1" ]]; then
        log_dry "find ${dir} -type f -mtime +${LOG_RETENTION_DAYS} -delete"
      else
        find "${dir}" -type f -mtime "+${LOG_RETENTION_DAYS}" -delete
      fi
    fi
  done

  if [[ -d "${MAC_SETUP_BACKUP_DIR}" ]]; then
    pruned="$(find "${MAC_SETUP_BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d \
      -mtime "+${BACKUP_RETENTION_DAYS}" | wc -l | tr -d ' ')"
    if [[ "${pruned}" -gt 0 ]] &&
      confirm "Delete ${pruned} dotfile backup set(s) older than ${BACKUP_RETENTION_DAYS} days?"; then
      if [[ "${DRY_RUN}" == "1" ]]; then
        log_dry "delete old backup sets under ${MAC_SETUP_BACKUP_DIR}"
      else
        find "${MAC_SETUP_BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d \
          -mtime "+${BACKUP_RETENTION_DAYS}" -exec rm -rf {} +
      fi
    fi
  fi
  log_success "State pruned."
}

# ---------------------------------------------------------------------------
# cleanup_docker — optional, destructive to unused images; always asks.
# ---------------------------------------------------------------------------
cleanup_docker() {
  has_command docker || return 0
  docker info >/dev/null 2>&1 || return 0
  log_step "Docker"
  if confirm "Run 'docker system prune' (removes stopped containers & unused images)?"; then
    run docker system prune -f
  else
    log_info "Skipping Docker prune."
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n | --dry-run) DRY_RUN=1 ;;
      -v | --verbose) VERBOSE=1 ;;
      -y | --yes) MAC_SETUP_YES=1 ;;
      -h | --help)
        sed -n '2,13{s/^# \{0,1\}//p;}' "${BASH_SOURCE[0]}"
        exit 0
        ;;
      *)
        log_error "Unknown option: $1"
        exit 2
        ;;
    esac
    shift
  done
  export DRY_RUN VERBOSE MAC_SETUP_YES="${MAC_SETUP_YES:-0}"

  require_macos
  ensure_state_dirs

  cleanup_brew
  cleanup_state
  cleanup_docker
  log_success "Cleanup complete."
}

main "$@"
