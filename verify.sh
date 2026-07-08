#!/usr/bin/env bash
#
# verify.sh — Verify the installation and print a summary.
#
# Thin wrapper around scripts/verification.sh so verification is a
# first-class, top-level command:
#
#   ./verify.sh              # full verification + report
#   ./verify.sh --verbose    # with debug output
#
# Exit code 0 = everything required is present.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  -v | --verbose) export VERBOSE=1 ;;
  -h | --help)
    sed -n '2,12{s/^# \{0,1\}//p;}' "${BASH_SOURCE[0]}"
    exit 0
    ;;
esac

exec bash "${SCRIPT_DIR}/scripts/verification.sh"
