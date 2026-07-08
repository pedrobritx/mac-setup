#!/usr/bin/env bash
#
# scripts/directories.sh — Create the organized home directory layout.
#
# The directory list lives in config/settings.sh (MAC_SETUP_DIRECTORIES),
# with paths relative to $HOME. Creation is idempotent; nothing is ever
# moved or deleted.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="directories"

# ---------------------------------------------------------------------------
# create_directories — mkdir -p each configured directory under $HOME.
# ---------------------------------------------------------------------------
create_directories() {
  local rel dir
  for rel in "${MAC_SETUP_DIRECTORIES[@]}"; do
    dir="${HOME}/${rel}"
    if [[ -d "${dir}" ]]; then
      log_skip "~/${rel} exists."
      report_skip "${MODULE}" "~/${rel}" "already exists"
    else
      ensure_dir "${dir}"
      report_ok "${MODULE}" "~/${rel}" "created"
    fi
  done
}

# ---------------------------------------------------------------------------
# tag_developer_folder — ~/Developer gets its special hammer icon from
# macOS automatically once it exists; nothing else to do, but we verify.
# ---------------------------------------------------------------------------
tag_developer_folder() {
  if [[ -d "${HOME}/Developer" ]]; then
    log_debug "~/Developer present — Finder shows the hammer icon automatically."
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  create_directories
  tag_developer_folder
}

main "$@"
