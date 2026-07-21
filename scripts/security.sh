#!/usr/bin/env bash
#
# scripts/security.sh — Security hardening (conservative, developer-friendly).
#
#   * Application firewall on
#   * Touch ID for sudo
#   * Immediate screen lock after screensaver/sleep
#   * FileVault status check (enabling it is left manual — it needs a
#     recovery-key decision that shouldn't be scripted silently)
#
# Nothing here weakens security; nothing destructive.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="security"

# ---------------------------------------------------------------------------
# enable_firewall — turn on the macOS application firewall.
# ---------------------------------------------------------------------------
enable_firewall() {
  local fw="/usr/libexec/ApplicationFirewall/socketfilterfw"
  if [[ ! -x "${fw}" && "${DRY_RUN}" == "1" ]]; then
    log_dry "sudo ${fw} --setglobalstate on"
    return 0
  fi

  if "${fw}" --getglobalstate 2>/dev/null | grep -q "enabled"; then
    log_skip "Application firewall already enabled."
    report_skip "${MODULE}" "firewall" "already enabled"
    return 0
  fi

  if run sudo "${fw}" --setglobalstate on; then
    log_success "Application firewall enabled."
    report_ok "${MODULE}" "firewall" "enabled"
  else
    report_fail "${MODULE}" "firewall" "could not enable (sudo required)"
  fi
}

# ---------------------------------------------------------------------------
# enable_touchid_sudo — allow Touch ID for sudo via /etc/pam.d/sudo_local
# (survives macOS updates, unlike editing /etc/pam.d/sudo directly).
# ---------------------------------------------------------------------------
enable_touchid_sudo() {
  local pam_local="/etc/pam.d/sudo_local"
  local line="auth       sufficient     pam_tid.so"

  if [[ -f "${pam_local}" ]] && grep -q "pam_tid.so" "${pam_local}" &&
    ! grep -E "^#.*pam_tid.so" -q "${pam_local}"; then
    log_skip "Touch ID for sudo already enabled."
    report_skip "${MODULE}" "Touch ID sudo" "already enabled"
    return 0
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    log_dry "write '${line}' to ${pam_local}"
    return 0
  fi

  if printf '%s\n' "${line}" | sudo tee "${pam_local}" >/dev/null; then
    log_success "Touch ID enabled for sudo."
    report_ok "${MODULE}" "Touch ID sudo" "enabled via ${pam_local}"
  else
    report_fail "${MODULE}" "Touch ID sudo" "could not write ${pam_local}"
  fi
}

# ---------------------------------------------------------------------------
# require_password_after_sleep — lock the screen immediately.
# ---------------------------------------------------------------------------
require_password_after_sleep() {
  # sysadminctl controls this on modern macOS; defaults still works for the
  # legacy screensaver path and is harmless otherwise.
  defaults_write com.apple.screensaver askForPassword int 1 \
    "Require password after screensaver"
  defaults_write com.apple.screensaver askForPasswordDelay int 0 \
    "Require password immediately"
  report_ok "${MODULE}" "screen lock" "password required immediately after sleep/screensaver"
}

# ---------------------------------------------------------------------------
# check_filevault — report status; enabling stays a manual decision.
# ---------------------------------------------------------------------------
check_filevault() {
  if [[ "${DRY_RUN}" == "1" && "$(uname -s)" != "Darwin" ]]; then
    log_dry "fdesetup status"
    return 0
  fi

  if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
    log_success "FileVault is enabled."
    report_ok "${MODULE}" "FileVault" "enabled"
  else
    report_manual "${MODULE}" "FileVault disk encryption" \
      "https://support.apple.com/guide/mac-help/protect-data-on-your-mac-with-filevault-mh11785/mac" \
      "enabling FileVault requires choosing how to store the recovery key — a personal decision we don't automate" \
      "System Settings → Privacy & Security → FileVault → Turn On; store the recovery key somewhere safe (not on this Mac)"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  if [[ "${MAC_SETUP_ENABLE_SECURITY}" != "1" ]]; then
    log_skip "Security module disabled in config/settings.sh."
    report_skip "${MODULE}" "security" "disabled in settings"
    return 0
  fi

  # Each hardening step is an optional suggestion, ticked/unticked on the
  # selection screen or pinned in config/settings.sh (MAC_SETUP_PREF_*).
  # FileVault is only ever *reported*, never changed automatically.
  pref_enabled FIREWALL && enable_firewall
  pref_enabled TOUCHID_SUDO && enable_touchid_sudo
  pref_enabled SCREEN_LOCK && require_password_after_sleep
  check_filevault
}

main "$@"
