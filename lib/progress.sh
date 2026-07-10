#!/usr/bin/env bash
#
# lib/progress.sh — "X of Y installed, Z to go" progress across modules.
#
# The total is the number of packages (formulae + casks + mas apps) in the
# active Brewfile, computed once by install.sh and exported as
# MAC_SETUP_PROGRESS_TOTAL. Modules run as subprocesses, so the running
# count lives in a file keyed by the run id — each satisfied package
# appends one line and the count is the line count.
#
# Usage:
#   progress_tick "ripgrep"          → logs:  ✓ ripgrep  [12/52 · 40 to go]
#   progress_suffix                  → prints "[12/52 · 40 to go]" (or "")

if [[ -n "${_MAC_SETUP_PROGRESS_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_PROGRESS_LOADED=1

# Set by install.sh; empty means progress display is off (standalone module
# runs, update.sh, verify.sh).
MAC_SETUP_PROGRESS_TOTAL="${MAC_SETUP_PROGRESS_TOTAL:-}"
export MAC_SETUP_PROGRESS_TOTAL

_progress_file() {
  echo "${MAC_SETUP_STATE_DIR}/progress-${MAC_SETUP_RUN_ID}.ticks"
}

# progress_count — number of packages satisfied so far in this run.
progress_count() {
  local f
  f="$(_progress_file)"
  if [[ -f "${f}" ]]; then
    wc -l <"${f}" | tr -d ' '
  else
    echo 0
  fi
}

# progress_suffix — "[done/total · left to go]", or nothing when no total.
progress_suffix() {
  [[ -n "${MAC_SETUP_PROGRESS_TOTAL}" ]] || return 0
  local finished left
  finished="$(progress_count)"
  left=$((MAC_SETUP_PROGRESS_TOTAL - finished))
  ((left < 0)) && left=0
  printf '[%s/%s · %s to go]' "${finished}" "${MAC_SETUP_PROGRESS_TOTAL}" "${left}"
}

# progress_tick <label> [detail] — record one satisfied package and log it
# with the running count. Call it for fresh installs AND already-installed
# skips: both count toward "done" (the machine has the item either way).
# Idempotent per label, so a package reconciled twice (brew module, then the
# apps module's retry pass) is only counted once.
progress_tick() {
  local label="$1" detail="${2:-installed}" f
  [[ -n "${MAC_SETUP_PROGRESS_TOTAL}" ]] || return 0
  f="$(_progress_file)"
  if [[ -f "${f}" ]] && grep -qx "${label}" "${f}" 2>/dev/null; then
    log_debug "progress: ${label} already counted"
    return 0
  fi
  printf '%s\n' "${label}" >>"${f}"
  log_success "${label} — ${detail}  $(progress_suffix)"
}
