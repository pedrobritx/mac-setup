#!/usr/bin/env bash
#
# scripts/mas.sh — Mac App Store applications.
#
# MAS apps are declared in the Brewfile (section 5). The App Store is the
# PREFERRED source when an app exists both there and as a cask — one source
# per app means no duplicate copies. Because mas installs fail whenever the
# App Store is signed out or a paid app is unpurchased, this module:
#   * verifies each declared app is installed,
#   * installs what it can, with the shared progress counter,
#   * routes anything left to the manual-actions report with the official
#     App Store URL, the reason, and the manual steps.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="mas"

# ---------------------------------------------------------------------------
# brewfile_mas_entries — print "id<TAB>name" for each mas line in Brewfile.
# ---------------------------------------------------------------------------
brewfile_mas_entries() {
  grep -E '^mas "' "${MAC_SETUP_BREWFILE}" |
    sed -E 's/^mas "([^"]+)", id: ([0-9]+).*/\2\t\1/'
}

# ---------------------------------------------------------------------------
# check_signin — verify the machine can install from the App Store.
# ---------------------------------------------------------------------------
check_signin() {
  if ! has_command mas; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "mas not present (dry-run) — continuing."
      return 0
    fi
    report_fail "${MODULE}" "mas CLI" "not installed — run the brew module first"
    return 1
  fi

  if mas_signed_in; then
    log_success "App Store session detected."
    return 0
  fi

  log_warn "Not signed in to the App Store — MAS installs will be reported as manual."
  report_manual "${MODULE}" "App Store sign-in" \
    "https://support.apple.com/en-us/HT204053" \
    "mas cannot sign in programmatically on modern macOS" \
    "Open the App Store app, sign in with your Apple ID, then re-run: ./install.sh --only mas"
  return 1
}

# ---------------------------------------------------------------------------
# install_mas_app <id> <name> — idempotent install of one MAS app.
# ---------------------------------------------------------------------------
install_mas_app() {
  local id="$1" name="$2"

  if mas_app_installed "${id}" || app_installed "${name}"; then
    progress_tick "${name}" "already installed"
    report_skip "${MODULE}" "${name}" "already installed"
    return 0
  fi

  log_info "Installing ${name} (App Store id ${id})..."
  if run mas install "${id}"; then
    progress_tick "${name}" "installed from the App Store"
    report_ok "${MODULE}" "${name}" "installed via mas"
  else
    report_manual "${MODULE}" "${name}" \
      "https://apps.apple.com/app/id${id}" \
      "mas install failed — typically an unpurchased paid app or Apple ID issue" \
      "Open the App Store link, purchase/get the app once with your Apple ID, then re-run: ./install.sh --only mas"
  fi
}

# ---------------------------------------------------------------------------
# reconcile_mas_apps — walk every Brewfile mas entry.
# ---------------------------------------------------------------------------
reconcile_mas_apps() {
  local signed_in="$1" id name

  while IFS=$'\t' read -r id name; do
    if [[ "${signed_in}" == "1" || "${DRY_RUN}" == "1" ]]; then
      install_mas_app "${id}" "${name}"
    elif mas_app_installed "${id}" || app_installed "${name}"; then
      progress_tick "${name}" "already installed"
      report_skip "${MODULE}" "${name}" "already installed"
    else
      report_manual "${MODULE}" "${name}" \
        "https://apps.apple.com/app/id${id}" \
        "App Store not signed in" \
        "Sign in to the App Store, then run: mas install ${id}"
    fi
  done < <(brewfile_mas_entries)
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs
  ensure_brew_in_path

  local signed_in=1
  check_signin || signed_in=0
  reconcile_mas_apps "${signed_in}"
  if [[ "${MAC_SETUP_EXPLICIT_SELECTION:-0}" == "1" ]] && pref_enabled FULL_XCODE; then
    MAC_SETUP_XCODE_FINALISE=1 bash "${SCRIPT_DIR}/xcode.sh"
  fi
}

main "$@"
