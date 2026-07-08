#!/usr/bin/env bash
#
# scripts/fonts.sh — Developer fonts.
#
# Fonts are declared as casks in the Brewfile (section 4) and installed by
# scripts/brew.sh. This module:
#   * installs any font cask that brew bundle missed,
#   * verifies the font files actually landed in the Font directories,
#   * records recommendations for additional fonts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="fonts"

# ---------------------------------------------------------------------------
# brewfile_font_casks — print the (uncommented) font casks in the Brewfile.
# ---------------------------------------------------------------------------
brewfile_font_casks() {
  grep -E '^cask "font-' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^cask "([^"]+)".*/\1/'
}

# ---------------------------------------------------------------------------
# install_fonts — ensure every Brewfile font cask is installed.
# ---------------------------------------------------------------------------
install_fonts() {
  local cask
  while IFS= read -r cask; do
    if brew_cask_installed "${cask}"; then
      log_skip "${cask} already installed."
      report_skip "${MODULE}" "${cask}" "already installed"
    elif run brew install --cask "${cask}"; then
      log_success "Installed ${cask}."
      report_ok "${MODULE}" "${cask}" "installed"
    else
      report_fail "${MODULE}" "${cask}" "brew install --cask failed"
    fi
  done < <(brewfile_font_casks)
}

# ---------------------------------------------------------------------------
# verify_fonts — confirm JetBrains Mono files exist in the Font folders.
# ---------------------------------------------------------------------------
verify_fonts() {
  if font_installed "JetBrainsMono*"; then
    log_success "JetBrains Mono font files verified."
    report_ok "${MODULE}" "JetBrains Mono" "font files present"
  elif [[ "${DRY_RUN}" == "1" ]]; then
    log_debug "Skipping font file verification in dry-run."
  else
    report_fail "${MODULE}" "JetBrains Mono" "font files not found in ~/Library/Fonts"
  fi
}

# ---------------------------------------------------------------------------
# recommend_fonts — surface curated extras (kept commented in the Brewfile).
# ---------------------------------------------------------------------------
recommend_fonts() {
  log_info "Recommended extras (uncomment in Brewfile to install):"
  log_info "  font-fira-code, font-monaspace, font-geist-mono, font-cascadia-code"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if ! has_command brew && [[ "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "fonts" "Homebrew not installed — run the brew module first"
    exit 1
  fi

  install_fonts
  verify_fonts
  recommend_fonts
}

main "$@"
