#!/usr/bin/env bash
# web.sh — launch the guided browser companion without a Node dependency.
# A fresh Mac obtains Python 3 with Apple's Command Line Tools (bootstrap.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' "Python 3 is required. Install Apple's Command Line Tools with xcode-select --install, then try again." >&2
  exit 1
fi
cd "${SCRIPT_DIR}"
exec python3 -m web.server "$@"
