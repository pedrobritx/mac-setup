#!/usr/bin/env bash
#
# lib/report.sh — Result accumulation and report rendering.
#
# Modules record every outcome through report_* functions. Records are
# appended as TSV lines to $MAC_SETUP_REPORT_RAW, which survives across the
# module subprocesses spawned by install.sh. At the end of a run the
# orchestrator renders three Markdown reports into $MAC_SETUP_REPORT_DIR:
#
#   install-report.md      — everything that was installed/configured/skipped
#   manual-actions.md      — items that require a human (URL, reason, steps)
#   verification-report.md — rendered by scripts/verification.sh
#
# TSV schema (one record per line):
#   status <TAB> module <TAB> item <TAB> detail
# where status ∈ {OK, SKIP, FAIL, MANUAL}.

if [[ -n "${_MAC_SETUP_REPORT_LOADED:-}" ]]; then
  return 0
fi
_MAC_SETUP_REPORT_LOADED=1

# ---------------------------------------------------------------------------
# _report_append <status> <module> <item> <detail>
# Internal: append one record. Tabs/newlines in fields are flattened so the
# TSV stays parseable.
# ---------------------------------------------------------------------------
_report_append() {
  local status="$1" module="$2" item="$3" detail="${4:-}"
  mkdir -p "$(dirname "${MAC_SETUP_REPORT_RAW}")"
  printf '%s\t%s\t%s\t%s\n' \
    "${status}" \
    "${module//[$'\t\n']/ }" \
    "${item//[$'\t\n']/ }" \
    "${detail//[$'\t\n']/ }" >>"${MAC_SETUP_REPORT_RAW}"
}

# report_ok <module> <item> [detail] — record a successful action.
report_ok() { _report_append "OK" "$@"; }

# report_skip <module> <item> [detail] — record an already-satisfied action.
report_skip() { _report_append "SKIP" "$@"; }

# report_fail <module> <item> [detail] — record a failed action.
report_fail() { _report_append "FAIL" "$@"; }

# ---------------------------------------------------------------------------
# report_manual <module> <item> <url> <reason> <steps>
# Record an action that cannot be automated. Rendered into
# manual-actions.md with the official URL, the reason automation is not
# possible, and the manual steps to follow.
# ---------------------------------------------------------------------------
report_manual() {
  local module="$1" item="$2" url="$3" reason="$4" steps="$5"
  _report_append "MANUAL" "${module}" "${item}" "${url}|${reason}|${steps}"
  log_warn "Manual step required: ${item} (recorded in manual-actions.md)"
}

# ---------------------------------------------------------------------------
# report_counts — print "ok skip fail manual" totals for the current run.
# ---------------------------------------------------------------------------
report_counts() {
  local ok=0 skip=0 fail=0 manual=0
  if [[ -f "${MAC_SETUP_REPORT_RAW}" ]]; then
    ok="$(grep -c $'^OK\t' "${MAC_SETUP_REPORT_RAW}" || true)"
    skip="$(grep -c $'^SKIP\t' "${MAC_SETUP_REPORT_RAW}" || true)"
    fail="$(grep -c $'^FAIL\t' "${MAC_SETUP_REPORT_RAW}" || true)"
    manual="$(grep -c $'^MANUAL\t' "${MAC_SETUP_REPORT_RAW}" || true)"
  fi
  printf '%s %s %s %s\n' "${ok}" "${skip}" "${fail}" "${manual}"
}

# ---------------------------------------------------------------------------
# render_install_report [output_path]
# Render the Markdown install report from the raw TSV. Defaults to
# $MAC_SETUP_REPORT_DIR/install-report.md.
# ---------------------------------------------------------------------------
render_install_report() {
  local out="${1:-${MAC_SETUP_REPORT_DIR}/install-report.md}"
  local counts ok skip fail manual
  counts="$(report_counts)"
  read -r ok skip fail manual <<<"${counts}"

  mkdir -p "$(dirname "${out}")"
  {
    echo "# mac-setup — Install Report"
    echo
    echo "- **Run:** ${MAC_SETUP_RUN_ID}"
    echo "- **Date:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **Host:** $(hostname) (macOS $(macos_version), $(uname -m))"
    echo "- **Mode:** $([[ "${DRY_RUN:-0}" == "1" ]] && echo "dry-run" || echo "apply")"
    echo
    echo "| Result | Count |"
    echo "|--------|-------|"
    echo "| ✅ Installed / configured | ${ok} |"
    echo "| ⏭️ Already satisfied | ${skip} |"
    echo "| ❌ Failed | ${fail} |"
    echo "| ✋ Manual action needed | ${manual} |"
    echo
    echo "## Details"
    echo
    echo "| Status | Module | Item | Detail |"
    echo "|--------|--------|------|--------|"
    if [[ -f "${MAC_SETUP_REPORT_RAW}" ]]; then
      # MANUAL records carry structured detail; keep only the reason here.
      awk -F'\t' '$1 != "" {
        detail = $4
        if ($1 == "MANUAL") { split($4, p, "|"); detail = p[2] }
        icon = ($1 == "OK") ? "✅" : ($1 == "SKIP") ? "⏭️" : ($1 == "FAIL") ? "❌" : "✋"
        printf "| %s %s | %s | %s | %s |\n", icon, $1, $2, $3, detail
      }' "${MAC_SETUP_REPORT_RAW}"
    fi
    echo
    echo "_Log file: ${MAC_SETUP_LOG_FILE:-n/a}_"
  } >"${out}"

  log_info "Install report written to ${out/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# render_manual_report [output_path]
# Render manual-actions.md — one section per item that needs a human, with
# the official URL, the reason it cannot be automated, and the steps.
# ---------------------------------------------------------------------------
render_manual_report() {
  local out="${1:-${MAC_SETUP_REPORT_DIR}/manual-actions.md}"
  mkdir -p "$(dirname "${out}")"

  {
    echo "# mac-setup — Manual Actions"
    echo
    echo "Items below could not be fully automated. Work through them once;"
    echo "re-running \`./verify.sh\` afterwards confirms completion."
    echo
    if [[ -f "${MAC_SETUP_REPORT_RAW}" ]] &&
      grep -q $'^MANUAL\t' "${MAC_SETUP_REPORT_RAW}"; then
      awk -F'\t' '$1 == "MANUAL" {
        split($4, p, "|")
        printf "## %s\n\n", $3
        printf "- **Official URL:** %s\n", p[1]
        printf "- **Why manual:** %s\n", p[2]
        printf "- **Steps:** %s\n\n", p[3]
      }' "${MAC_SETUP_REPORT_RAW}"
    else
      echo "🎉 Nothing to do — every item was automated."
    fi
  } >"${out}"

  log_info "Manual-actions report written to ${out/#${HOME}/~}"
}

# ---------------------------------------------------------------------------
# print_summary — colored end-of-run summary for the terminal.
# ---------------------------------------------------------------------------
print_summary() {
  local counts ok skip fail manual
  counts="$(report_counts)"
  read -r ok skip fail manual <<<"${counts}"

  printf '\n%b%s%b\n' "${C_BOLD}" "────────────────── Summary ──────────────────" "${C_RESET}"
  printf '  %b✓ done%b      %s\n' "${C_GREEN}" "${C_RESET}" "${ok}"
  printf '  %b⏭ skipped%b   %s\n' "${C_DIM}" "${C_RESET}" "${skip}"
  printf '  %b✗ failed%b    %s\n' "${C_RED}" "${C_RESET}" "${fail}"
  printf '  %b✋ manual%b    %s\n' "${C_YELLOW}" "${C_RESET}" "${manual}"
  printf '%b%s%b\n' "${C_BOLD}" "──────────────────────────────────────────────" "${C_RESET}"
}
