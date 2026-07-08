# ~/.zprofile — login-shell environment (managed by mac-setup).
#
# Runs once per login shell, before .zshrc. Keep it minimal: PATH and
# environment only. Interactive configuration belongs in .zshrc.

# Homebrew — sets PATH/MANPATH/INFOPATH and HOMEBREW_* vars.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Session-wide environment (EDITOR, LANG, XDG dirs, tool knobs).
[[ -f "${HOME}/.config/zsh/exports.zsh" ]] && source "${HOME}/.config/zsh/exports.zsh"
