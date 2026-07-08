#!/usr/bin/env bash
#
# scripts/swift.sh — Swift toolchain.
#
# Swift itself ships with the Xcode Command Line Tools / Xcode (handled by
# scripts/xcode.sh). This module verifies the compiler and wires up the
# ecosystem tooling from the Brewfile (SwiftFormat, SwiftLint).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="swift"

# ---------------------------------------------------------------------------
# verify_swift — confirm the Swift compiler from CLT/Xcode works.
# ---------------------------------------------------------------------------
verify_swift() {
  if ! has_command swift; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "swift --version"
      return 0
    fi
    report_fail "${MODULE}" "swift" "compiler not found — run the xcode module first"
    return 1
  fi

  local version
  version="$(swift --version 2>/dev/null | head -n1 || true)"
  log_success "Swift available: ${version}"
  report_ok "${MODULE}" "swift" "${version}"
}

# ---------------------------------------------------------------------------
# verify_tooling — SwiftFormat and SwiftLint from the Brewfile.
# ---------------------------------------------------------------------------
verify_tooling() {
  local tool
  for tool in swiftformat swiftlint; do
    if has_command "${tool}"; then
      log_success "${tool} $(${tool} --version 2>/dev/null | head -n1) available."
      report_ok "${MODULE}" "${tool}" "version $(${tool} --version 2>/dev/null | head -n1)"
    elif [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "${tool} missing (dry-run)"
    else
      report_fail "${MODULE}" "${tool}" "not found — check the brew module output"
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

  verify_swift
  verify_tooling
}

main "$@"
