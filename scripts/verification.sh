#!/usr/bin/env bash
#
# scripts/verification.sh — Verify the whole installation.
#
# Checks every layer of the setup — package manager, toolchains, apps,
# fonts, terminal plugins, dotfile links — prints an aligned, colored
# summary table, and writes verification-report.md.
#
# Exit code: 0 when everything passes, 1 otherwise (usable in CI/cron).
# Run standalone any time via ./verify.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="verify"

# Accumulated results: "status<TAB>category<TAB>name<TAB>detail"
VERIFY_RESULTS=()
VERIFY_PASS=0
VERIFY_FAIL=0
VERIFY_WARN=0

# ---------------------------------------------------------------------------
# check <category> <name> <command...> — run a probe; record pass/fail.
# Always returns 0 (failures are tallied, not propagated) so a failed probe
# doesn't abort the run under `set -e`.
# ---------------------------------------------------------------------------
check() {
  local category="$1" name="$2"
  shift 2
  local detail
  if detail="$("$@" 2>/dev/null | head -n1)" && [[ -n "${detail}" ]]; then
    VERIFY_RESULTS+=("PASS	${category}	${name}	${detail}")
    VERIFY_PASS=$((VERIFY_PASS + 1))
    return 0
  fi
  VERIFY_RESULTS+=("FAIL	${category}	${name}	not available")
  VERIFY_FAIL=$((VERIFY_FAIL + 1))
  return 0
}

# check_warn <category> <name> <command...> — like check, but a miss is a
# warning (optional components) rather than a failure.
check_warn() {
  local category="$1" name="$2"
  shift 2
  local detail
  if detail="$("$@" 2>/dev/null | head -n1)" && [[ -n "${detail}" ]]; then
    VERIFY_RESULTS+=("PASS	${category}	${name}	${detail}")
    VERIFY_PASS=$((VERIFY_PASS + 1))
    return 0
  fi
  VERIFY_RESULTS+=("WARN	${category}	${name}	not available (optional)")
  VERIFY_WARN=$((VERIFY_WARN + 1))
  return 0
}

# probe helpers ------------------------------------------------------------

# _version <cmd> <args...> — print a tool's version line (probe for check).
_version() { command -v "$1" >/dev/null 2>&1 && "$@"; }

# _app <App Name> — probe an installed .app bundle.
_app() { app_installed "$1" && echo "installed"; }

# _font <glob> — probe a font file.
_font() { font_installed "$1" && echo "present"; }

# _plugin <relpath> — probe a zsh plugin under the brew prefix.
_plugin() { [[ -f "$(brew_prefix)/$1" ]] && echo "present"; }

# _link <target> — probe that a path is a symlink into this repository.
_link() {
  [[ -L "$1" && "$(readlink "$1")" == "${MAC_SETUP_ROOT}"* ]] && echo "linked"
}

# ---------------------------------------------------------------------------
# run_checks — every probe, grouped by category.
# ---------------------------------------------------------------------------
run_checks() {
  # Core
  check "core" "Xcode CLT" bash -c 'xcode-select -p'
  check "core" "Homebrew" _version brew --version
  check "core" "git" _version git --version
  check_warn "core" "gh (GitHub CLI)" _version gh --version
  check_warn "core" "git-lfs" _version git-lfs --version

  # Languages
  check "lang" "node" _version node --version
  check_warn "lang" "fnm" _version fnm --version
  check_warn "lang" "pnpm" _version pnpm --version
  check_warn "lang" "bun" _version bun --version
  check "lang" "python (uv)" _version uv --version
  check_warn "lang" "pipx" _version pipx --version
  check "lang" "swift" bash -c 'swift --version 2>&1 | head -n1'
  check_warn "lang" "swiftformat" _version swiftformat --version
  check_warn "lang" "swiftlint" _version swiftlint --version

  # Docker
  check_warn "docker" "docker CLI" _version docker --version
  check_warn "docker" "docker daemon" bash -c 'docker info >/dev/null 2>&1 && echo running'
  check_warn "docker" "docker compose" bash -c 'docker compose version --short'

  # Terminal tools
  local tool
  for tool in starship zoxide fzf eza bat fd rg jq yq tree wget atuin btop htop tmux fastfetch nvim; do
    check "terminal" "${tool}" _version "${tool}" --version
  done

  # zsh plugins
  check "terminal" "zsh-autosuggestions" _plugin "share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  check "terminal" "zsh-syntax-highlighting" _plugin "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  check "terminal" "zsh-history-substring-search" _plugin "share/zsh-history-substring-search/zsh-history-substring-search.zsh"

  # Dotfile links
  check "dotfiles" ".zshrc" _link "${HOME}/.zshrc"
  check "dotfiles" ".zprofile" _link "${HOME}/.zprofile"
  check "dotfiles" "starship.toml" _link "${HOME}/.config/starship.toml"
  check "dotfiles" "git config" _link "${HOME}/.config/git/config"

  # Fonts
  check "fonts" "JetBrains Mono" _font "JetBrainsMono*"

  # Applications (from the Brewfile cask list)
  local cask name
  while IFS= read -r cask; do
    check_warn "apps" "${cask}" bash -c \
      "brew list --cask --versions '${cask}' >/dev/null 2>&1 && echo installed"
  done < <(grep -E '^cask "' "${MAC_SETUP_BREWFILE}" | grep -v '"font-' |
    sed -E 's/^cask "([^"]+)".*/\1/')

  # Mac App Store apps (by name, so manually installed copies also count)
  while IFS=$'\t' read -r _ name; do
    check_warn "mas" "${name}" _app "${name}"
  done < <(grep -E '^mas "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^mas "([^"]+)", id: ([0-9]+).*/\2\t\1/')
}

# ---------------------------------------------------------------------------
# print_table — aligned, colored summary grouped by category.
# ---------------------------------------------------------------------------
print_table() {
  local row status category name detail last_category=""

  printf '\n%b%-8s %-34s %s%b\n' "${C_BOLD}" "STATUS" "CHECK" "DETAIL" "${C_RESET}"
  printf '%s\n' "───────────────────────────────────────────────────────────────────"

  for row in "${VERIFY_RESULTS[@]}"; do
    IFS=$'\t' read -r status category name detail <<<"${row}"
    if [[ "${category}" != "${last_category}" ]]; then
      printf '%b%s%b\n' "${C_CYAN}${C_BOLD}" "── ${category} ──" "${C_RESET}"
      last_category="${category}"
    fi
    case "${status}" in
      PASS) printf '  %b%-6s%b %-34s %b%s%b\n' "${C_GREEN}" "✓ ok" "${C_RESET}" "${name}" "${C_DIM}" "${detail}" "${C_RESET}" ;;
      WARN) printf '  %b%-6s%b %-34s %b%s%b\n' "${C_YELLOW}" "! warn" "${C_RESET}" "${name}" "${C_DIM}" "${detail}" "${C_RESET}" ;;
      FAIL) printf '  %b%-6s%b %-34s %s\n' "${C_RED}" "✗ FAIL" "${C_RESET}" "${name}" "${detail}" ;;
    esac
  done

  printf '%s\n' "───────────────────────────────────────────────────────────────────"
  printf '%b%d passed%b · %b%d warnings%b · %b%d failed%b\n\n' \
    "${C_GREEN}" "${VERIFY_PASS}" "${C_RESET}" \
    "${C_YELLOW}" "${VERIFY_WARN}" "${C_RESET}" \
    "${C_RED}" "${VERIFY_FAIL}" "${C_RESET}"
}

# ---------------------------------------------------------------------------
# write_report — verification-report.md in the reports directory.
# ---------------------------------------------------------------------------
write_report() {
  local out="${MAC_SETUP_REPORT_DIR}/verification-report.md"
  mkdir -p "${MAC_SETUP_REPORT_DIR}"
  {
    echo "# mac-setup — Verification Report"
    echo
    echo "- **Date:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **Host:** $(hostname) (macOS $(macos_version), $(uname -m))"
    echo "- **Result:** ${VERIFY_PASS} passed, ${VERIFY_WARN} warnings, ${VERIFY_FAIL} failed"
    echo
    echo "| Status | Category | Check | Detail |"
    echo "|--------|----------|-------|--------|"
    local row status category name detail
    for row in "${VERIFY_RESULTS[@]}"; do
      IFS=$'\t' read -r status category name detail <<<"${row}"
      local icon="✅"
      [[ "${status}" == "WARN" ]] && icon="⚠️"
      [[ "${status}" == "FAIL" ]] && icon="❌"
      printf '| %s %s | %s | %s | %s |\n' "${icon}" "${status}" "${category}" "${name}" "${detail}"
    done
  } >"${out}"
  log_info "Verification report written to ${out/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  # fnm-managed node lives outside PATH in non-interactive shells.
  if has_command fnm; then
    eval "$(fnm env 2>/dev/null)" || true
  fi

  log_info "Verifying installation..."
  run_checks
  print_table
  write_report

  if [[ "${DRY_RUN}" == "1" ]]; then
    # In a dry-run nothing was installed, so failures are expected and
    # informational — don't fail the run over them.
    log_info "Dry-run: verification results are informational only."
    report_skip "${MODULE}" "verification" "dry-run (informational): ${VERIFY_PASS} pass, ${VERIFY_FAIL} fail"
    return 0
  fi

  if [[ "${VERIFY_FAIL}" -gt 0 ]]; then
    report_fail "${MODULE}" "verification" "${VERIFY_FAIL} check(s) failed"
    exit 1
  fi
  report_ok "${MODULE}" "verification" "${VERIFY_PASS} checks passed, ${VERIFY_WARN} warnings"
  log_success "Verification passed."
}

main "$@"
