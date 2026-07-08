#!/usr/bin/env bash
#
# scripts/terminal.sh — Shell environment.
#
#   * Links the zsh dotfiles (.zshrc, .zprofile, modular zsh config).
#   * Links the Starship prompt configuration.
#   * Verifies the CLI tools & zsh plugins from the Brewfile are usable.
#   * Installs fzf keybindings.
#
# All tools (starship, zoxide, fzf, eza, bat, fd, ripgrep, jq, yq, tree,
# wget, atuin, btop, htop, tmux, fastfetch, neovim, zsh-* plugins) are
# installed by scripts/brew.sh from the Brewfile; this module wires them up.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

readonly MODULE="terminal"

# ---------------------------------------------------------------------------
# link_shell_dotfiles — symlink zsh + starship configuration into $HOME.
# Existing real files are backed up automatically by link_file.
# ---------------------------------------------------------------------------
link_shell_dotfiles() {
  link_file "${MAC_SETUP_DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
  link_file "${MAC_SETUP_DOTFILES_DIR}/.zprofile" "${HOME}/.zprofile"
  link_file "${MAC_SETUP_DOTFILES_DIR}/.config/zsh" "${HOME}/.config/zsh"
  link_file "${MAC_SETUP_DOTFILES_DIR}/.config/starship.toml" \
    "${HOME}/.config/starship.toml"
  report_ok "${MODULE}" "shell dotfiles" ".zshrc, .zprofile, zsh modules, starship.toml linked"
}

# ---------------------------------------------------------------------------
# verify_tools — confirm each terminal tool from the Brewfile is on PATH.
# ---------------------------------------------------------------------------
verify_tools() {
  local tools=(starship zoxide fzf eza bat fd rg jq yq tree wget atuin
    btop htop tmux fastfetch nvim)
  local tool missing=0

  ensure_brew_in_path
  for tool in "${tools[@]}"; do
    if has_command "${tool}"; then
      log_debug "${tool} present"
    elif [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "${tool} missing (dry-run — brew module has not run)"
    else
      log_warn "${tool} not found on PATH."
      report_fail "${MODULE}" "${tool}" "not found — check the brew module output"
      missing=1
    fi
  done

  if [[ "${missing}" -eq 0 ]]; then
    log_success "All terminal tools available."
    report_ok "${MODULE}" "CLI tools" "${#tools[@]} tools verified"
  fi
}

# ---------------------------------------------------------------------------
# verify_zsh_plugins — confirm the brew-installed plugin files exist; they
# are sourced directly from the brew prefix by dotfiles/.zshrc.
# ---------------------------------------------------------------------------
verify_zsh_plugins() {
  local prefix plugin
  prefix="$(brew_prefix)"
  local plugins=(
    "share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  )

  for plugin in "${plugins[@]}"; do
    if [[ -f "${prefix}/${plugin}" ]]; then
      log_debug "plugin present: ${plugin}"
    elif [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "plugin missing (dry-run): ${plugin}"
    else
      report_fail "${MODULE}" "${plugin##*/}" "plugin file missing under ${prefix}"
      return 0
    fi
  done
  log_success "zsh plugins present (sourced from the brew prefix by .zshrc)."
  report_ok "${MODULE}" "zsh plugins" "autosuggestions, syntax-highlighting, history-substring-search"
}

# ---------------------------------------------------------------------------
# ensure_default_shell — make sure the login shell is zsh (macOS default,
# but may differ on migrated accounts).
# ---------------------------------------------------------------------------
ensure_default_shell() {
  if [[ "${SHELL:-}" == */zsh ]]; then
    log_skip "Login shell is already zsh."
    report_skip "${MODULE}" "login shell" "already zsh"
    return 0
  fi
  if run chsh -s /bin/zsh; then
    report_ok "${MODULE}" "login shell" "changed to /bin/zsh"
  else
    report_fail "${MODULE}" "login shell" "chsh failed — run: chsh -s /bin/zsh"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
  require_macos
  ensure_state_dirs

  link_shell_dotfiles
  verify_tools
  verify_zsh_plugins
  ensure_default_shell
}

main "$@"
