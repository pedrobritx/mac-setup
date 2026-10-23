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

# configure_framework — opt into Oh My Zsh without replacing its config or
# hiding the choice in the shared dotfiles. Existing installations are reused.
configure_framework() {
  local mode=0 config="${HOME}/.config/mac-setup/shell.zsh"
  if pref_enabled OHMYZSH; then
    mode=1
    if [[ ! -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
      if [[ -e "${HOME}/.oh-my-zsh" ]]; then
        report_manual "${MODULE}" "Oh My Zsh" \
          "https://ohmyz.sh/" \
          "an existing .oh-my-zsh directory is incomplete; it was preserved" \
          "Review that directory, then repair your installation or deselect Oh My Zsh"
        return 0
      fi
      if ! run_retry 2 git clone --depth 1 \
        https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"; then
        report_fail "${MODULE}" "Oh My Zsh" "official repository could not be cloned"
        return 0
      fi
    fi
  fi
  local choice="shell-starship.zsh"
  [[ "${mode}" == "1" ]] && choice="shell-ohmyzsh.zsh"
  link_file "${MAC_SETUP_DOTFILES_DIR}/.config/mac-setup/${choice}" "${config}"
  report_ok "${MODULE}" "shell framework" "Oh My Zsh enabled: ${mode}; Starship prompt retained"
}

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

# _terminal_tool_formula <binary> — the Brewfile formula name behind a
# binary, for the two tools whose command name differs from the formula
# (ripgrep -> rg, neovim -> nvim). Everything else maps to itself.
_terminal_tool_formula() {
  case "$1" in
    rg) echo ripgrep ;;
    nvim) echo neovim ;;
    *) echo "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
# verify_tools — confirm each terminal tool from the Brewfile is on PATH.
# Tools unticked in the Brewfile selection are skipped, not failed.
# ---------------------------------------------------------------------------
verify_tools() {
  local tools=(starship zoxide fzf eza bat fd rg jq yq tree wget atuin
    btop htop tmux fastfetch nvim)
  local tool formula missing=0

  ensure_brew_in_path
  for tool in "${tools[@]}"; do
    if has_command "${tool}"; then
      log_debug "${tool} present"
      continue
    fi
    formula="$(_terminal_tool_formula "${tool}")"
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "${tool} missing (dry-run — brew module has not run)"
    elif ! brewfile_formula_selected "${formula}"; then
      log_debug "${tool} unticked in the Brewfile selection — skipping."
      report_skip "${MODULE}" "${tool}" "unticked in Brewfile selection"
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
    "share/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh"
  )

  local formula all_present=1
  for plugin in "${plugins[@]}"; do
    if [[ -f "${prefix}/${plugin}" ]]; then
      log_debug "plugin present: ${plugin}"
      continue
    fi
    formula="${plugin#*/}"
    formula="${formula%%/*}"
    if [[ "${DRY_RUN}" == "1" ]]; then
      log_debug "plugin missing (dry-run): ${plugin}"
    elif ! brewfile_formula_selected "${formula}"; then
      log_debug "${formula} unticked in the Brewfile selection — skipping."
      report_skip "${MODULE}" "${formula}" "unticked in Brewfile selection"
    else
      report_fail "${MODULE}" "${plugin##*/}" "plugin file missing under ${prefix}"
      all_present=0
    fi
  done
  if [[ "${all_present}" -eq 1 ]]; then
    log_success "zsh plugins present (sourced from the brew prefix by .zshrc)."
    report_ok "${MODULE}" "zsh plugins" "autosuggestions, syntax-highlighting, history-substring-search"
  fi
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
  configure_framework
  verify_tools
  verify_zsh_plugins
  ensure_default_shell
}

main "$@"
