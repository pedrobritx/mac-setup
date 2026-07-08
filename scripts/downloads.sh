#!/usr/bin/env bash
#
# scripts/downloads.sh — Keep ~/Downloads organized.
#
#   * Ensures ~/Downloads/Installers exists as the landing zone for .dmg /
#     .pkg files.
#   * Optionally sweeps existing installer files into it (only with
#     confirmation — nothing is deleted, only moved).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="downloads"
readonly INSTALLERS_DIR="${HOME}/Downloads/Installers"

# ---------------------------------------------------------------------------
# ensure_installers_dir — create ~/Downloads/Installers.
# ---------------------------------------------------------------------------
ensure_installers_dir() {
  if [[ -d "${INSTALLERS_DIR}" ]]; then
    log_skip "~/Downloads/Installers exists."
    report_skip "${MODULE}" "Installers folder" "already exists"
  else
    ensure_dir "${INSTALLERS_DIR}"
    report_ok "${MODULE}" "Installers folder" "created"
  fi
}

# ---------------------------------------------------------------------------
# sweep_installers — move loose .dmg/.pkg files from ~/Downloads into the
# Installers folder. Move-only (never deletes), skipped unless confirmed.
# ---------------------------------------------------------------------------
sweep_installers() {
  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "${HOME}/Downloads" -maxdepth 1 -type f \
    \( -name '*.dmg' -o -name '*.pkg' \) -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_debug "No loose installer files in ~/Downloads."
    return 0
  fi

  log_info "Found ${#files[@]} installer file(s) loose in ~/Downloads."
  if ! confirm "Move them into ~/Downloads/Installers?"; then
    log_info "Leaving ~/Downloads untouched."
    return 0
  fi

  local f
  for f in "${files[@]}"; do
    run mv -n "$f" "${INSTALLERS_DIR}/"
  done
  report_ok "${MODULE}" "Installer sweep" "moved ${#files[@]} file(s) into Installers/"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  ensure_installers_dir
  sweep_installers
}

main "$@"
