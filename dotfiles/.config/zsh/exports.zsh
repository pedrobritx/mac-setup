# exports.zsh — environment variables (managed by mac-setup).
# Sourced by both .zprofile (login) and .zshrc (interactive).

# Editors
export EDITOR="nvim"
export VISUAL="code --wait"

# Locale
export LANG="en_US.UTF-8"

# XDG base directories — keeps tool state out of a cluttered $HOME
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"
export XDG_CACHE_HOME="${HOME}/.cache"

# Homebrew
export HOMEBREW_NO_ENV_HINTS=1        # quieter brew output
export HOMEBREW_BUNDLE_FILE="${HOME}/Developer/mac-setup/Brewfile"

# bat as the pager for man pages (syntax-highlighted manuals)
command -v bat >/dev/null && export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# fzf — sensible defaults, fd as the walker (respects .gitignore)
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# pnpm global bin
export PNPM_HOME="${HOME}/Library/pnpm"
[[ -d "${PNPM_HOME}" ]] && export PATH="${PNPM_HOME}:${PATH}"

# bun
export BUN_INSTALL="${HOME}/.bun"
[[ -d "${BUN_INSTALL}/bin" ]] && export PATH="${BUN_INSTALL}/bin:${PATH}"

# pipx / uv tool shims
[[ -d "${HOME}/.local/bin" ]] && export PATH="${HOME}/.local/bin:${PATH}"
