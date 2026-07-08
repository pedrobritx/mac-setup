#!/usr/bin/env bash
#
# lib/log.sh — Colored, leveled logging for mac-setup.
#
# Every message goes to the terminal (with color, when attached to a TTY and
# NO_COLOR is unset) and, when MAC_SETUP_LOG_FILE is set, is appended to that
# file without color codes so logs stay grep-able.
#
# Levels:
#   log_step    — start of a major phase (bold heading)
#   log_info    — normal progress
#   log_debug   — only shown when VERBOSE=1
#   log_success — a completed action
#   log_warn    — recoverable problem
#   log_error   — failure (goes to stderr)
#   log_skip    — an action skipped because it was already done

if [[ -n "${_MAC_SETUP_LOG_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_LOG_LOADED=1

# ---------------------------------------------------------------------------
# Colors — enabled only on a TTY, disabled by NO_COLOR (https://no-color.org)
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_MAGENTA=$'\033[35m'
  C_CYAN=$'\033[36m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
  C_MAGENTA='' C_CYAN=''
fi
export C_RESET C_BOLD C_DIM C_RED C_GREEN C_YELLOW C_BLUE C_MAGENTA C_CYAN

# Plain-text log file shared across the orchestrator and module subprocesses.
MAC_SETUP_LOG_FILE="${MAC_SETUP_LOG_FILE:-}"
export MAC_SETUP_LOG_FILE

# ---------------------------------------------------------------------------
# _log <level> <color> <symbol> <message...> — internal formatter.
# Prints "<symbol> message" colored to the terminal and appends
# "<timestamp> [LEVEL] message" to the log file when one is configured.
# ---------------------------------------------------------------------------
_log() {
  local level="$1" color="$2" symbol="$3"
  shift 3
  local msg="$*"
  local stream=1
  [[ "${level}" == "ERROR" ]] && stream=2

  if [[ "${stream}" -eq 2 ]]; then
    printf '%b%s%b %s\n' "${color}" "${symbol}" "${C_RESET}" "${msg}" >&2
  else
    printf '%b%s%b %s\n' "${color}" "${symbol}" "${C_RESET}" "${msg}"
  fi

  if [[ -n "${MAC_SETUP_LOG_FILE}" ]]; then
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "${msg}" \
      >>"${MAC_SETUP_LOG_FILE}" 2>/dev/null || true
  fi
}

# log_step <message> — bold section heading for a major phase.
log_step() {
  printf '\n'
  _log "STEP" "${C_MAGENTA}${C_BOLD}" "==>" "${C_BOLD}$*${C_RESET}"
}

# log_info <message> — normal progress output.
log_info() { _log "INFO" "${C_BLUE}" "•" "$@"; }

# log_debug <message> — shown only when VERBOSE=1 (always written to file).
log_debug() {
  if [[ "${VERBOSE:-0}" == "1" ]]; then
    _log "DEBUG" "${C_DIM}" "‣" "$@"
  elif [[ -n "${MAC_SETUP_LOG_FILE}" ]]; then
    printf '%s [DEBUG] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
      >>"${MAC_SETUP_LOG_FILE}" 2>/dev/null || true
  fi
}

# log_success <message> — completed action.
log_success() { _log "OK" "${C_GREEN}" "✓" "$@"; }

# log_warn <message> — recoverable problem; execution continues.
log_warn() { _log "WARN" "${C_YELLOW}" "!" "$@"; }

# log_error <message> — failure; printed to stderr.
log_error() { _log "ERROR" "${C_RED}" "✗" "$@"; }

# log_skip <message> — action skipped because it is already satisfied.
log_skip() { _log "SKIP" "${C_DIM}" "⏭" "$@"; }

# log_dry <message> — echo of a command suppressed by dry-run mode.
log_dry() { _log "DRY" "${C_CYAN}" "▷" "would run: $*"; }
