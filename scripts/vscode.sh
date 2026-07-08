#!/usr/bin/env bash
#
# scripts/vscode.sh — Visual Studio Code.
#
#   * The app is installed by the Brewfile cask (visual-studio-code).
#   * Links settings.json and snippets from dotfiles/vscode/ so edits are
#     version-controlled.
#   * Installs every extension listed in dotfiles/vscode/extensions.txt.
#
# To capture your current extensions back into the repo:
#   code --list-extensions > dotfiles/vscode/extensions.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="vscode"
readonly VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
readonly VSCODE_DOTFILES="${MAC_SETUP_DOTFILES_DIR}/vscode"

# ---------------------------------------------------------------------------
# ensure_cli — the `code` command ships inside the app bundle; expose it.
# ---------------------------------------------------------------------------
ensure_cli() {
  if has_command code; then
    return 0
  fi
  local bundled="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ -x "${bundled}" ]]; then
    local bin_dir
    bin_dir="$(dirname "${bundled}")"
    export PATH="${PATH}:${bin_dir}"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# link_settings — symlink settings.json and snippets into the VS Code
# user directory. Existing files are backed up by link_file.
# ---------------------------------------------------------------------------
link_settings() {
  if [[ ! -d "/Applications/Visual Studio Code.app" && "${DRY_RUN}" != "1" ]]; then
    report_fail "${MODULE}" "VS Code" "app not installed — run the brew module first"
    return 1
  fi

  link_file "${VSCODE_DOTFILES}/settings.json" "${VSCODE_USER_DIR}/settings.json"
  link_file "${VSCODE_DOTFILES}/snippets" "${VSCODE_USER_DIR}/snippets"
  report_ok "${MODULE}" "settings" "settings.json + snippets linked"
}

# ---------------------------------------------------------------------------
# install_extensions — install everything from extensions.txt (idempotent;
# already-installed extensions are skipped).
# ---------------------------------------------------------------------------
install_extensions() {
  local list="${VSCODE_DOTFILES}/extensions.txt"
  [[ -f "${list}" ]] || {
    report_fail "${MODULE}" "extensions" "extensions.txt missing"
    return 1
  }

  if ! ensure_cli; then
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_dry "code --install-extension <each entry in extensions.txt>"
      return 0
    fi
    report_fail "${MODULE}" "extensions" "'code' CLI unavailable"
    return 1
  fi

  local ext installed=0 skipped=0 failed=0
  while IFS= read -r ext; do
    # Allow comments and blank lines in extensions.txt.
    [[ -z "${ext}" || "${ext}" == \#* ]] && continue

    if vscode_extension_installed "${ext}"; then
      log_debug "extension present: ${ext}"
      skipped=$((skipped + 1))
    elif run_quiet code --install-extension "${ext}"; then
      log_success "Installed extension: ${ext}"
      installed=$((installed + 1))
    else
      log_warn "Failed to install extension: ${ext}"
      report_fail "${MODULE}" "${ext}" "code --install-extension failed"
      failed=$((failed + 1))
    fi
  done <"${list}"

  log_info "Extensions: ${installed} installed, ${skipped} already present, ${failed} failed."
  report_ok "${MODULE}" "extensions" "${installed} installed, ${skipped} present, ${failed} failed"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  link_settings || return 0
  install_extensions
}

main "$@"
