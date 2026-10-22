# ~/.zshrc — interactive shell configuration (managed by mac-setup).
#
# Design goals:
#   * FAST startup: no framework, no plugin manager. Plugins are sourced
#     straight from the Homebrew prefix; completions are cached daily.
#   * Modular: aliases/functions/exports live in ~/.config/zsh/*.zsh.
#   * Everything is optional: each tool is guarded, so a missing tool never
#     breaks the shell.
#
# Measure startup any time with:  time zsh -i -c exit

# --- Homebrew prefix (also set by .zprofile; kept here for non-login shells)
if [[ -z "${HOMEBREW_PREFIX:-}" ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ----------------------------------------------------------------------------
# History — big, shared, deduplicated. atuin (below) supersedes the UI but
# plain history remains the durable store.
# ----------------------------------------------------------------------------
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY          # share across sessions
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_REDUCE_BLANKS     # trim superfluous whitespace
setopt HIST_VERIFY            # expand ! history before running
setopt INC_APPEND_HISTORY     # write as you go, not at exit

# ----------------------------------------------------------------------------
# Shell behavior
# ----------------------------------------------------------------------------
setopt AUTO_CD                # `..` and dir names cd by themselves
setopt CORRECT                # suggest command typo fixes
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
unsetopt BEEP

# ----------------------------------------------------------------------------
# Completion — compinit with a daily cache to keep startup fast.
# ----------------------------------------------------------------------------
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  fpath=("${HOMEBREW_PREFIX}/share/zsh/site-functions" $fpath)
fi
# Framework choice is machine-local; the repository keeps its fast default.
[[ -f "${HOME}/.config/mac-setup/shell.zsh" ]] && source "${HOME}/.config/mac-setup/shell.zsh"
_mac_setup_omz_loaded=0
if [[ "${MAC_SETUP_USE_OH_MY_ZSH:-0}" == "1" && -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  ZSH="${HOME}/.oh-my-zsh"
  ZSH_THEME=""
  plugins=(git)
  command -v fzf >/dev/null && plugins+=(zsh-interactive-cd)
  source "${ZSH}/oh-my-zsh.sh"
  _mac_setup_omz_loaded=1
fi
autoload -Uz compinit
_zcompdump="${HOME}/.zcompdump"
# Only re-scan completions once a day; -C skips the (slow) security audit.
if [[ "${_mac_setup_omz_loaded}" != "1" ]]; then
  if [[ -n ${_zcompdump}(#qN.mh-24) ]]; then
    compinit -C -d "${_zcompdump}"
  else
    compinit -d "${_zcompdump}"
  fi
fi
unset _zcompdump _mac_setup_omz_loaded
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive

# ----------------------------------------------------------------------------
# Modular config: exports, aliases, functions
# ----------------------------------------------------------------------------
for _mod in exports aliases functions; do
  [[ -f "${HOME}/.config/zsh/${_mod}.zsh" ]] && source "${HOME}/.config/zsh/${_mod}.zsh"
done
unset _mod

# ----------------------------------------------------------------------------
# Tool hooks — each guarded so a missing tool is a silent no-op.
# ----------------------------------------------------------------------------
# fnm — Node version manager (auto-switches on .node-version/.nvmrc)
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd)"

# zoxide — smarter cd (`z <fragment>`)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# fzf — fuzzy finder keybindings (Ctrl-R history, Ctrl-T files)
command -v fzf >/dev/null && source <(fzf --zsh)

# atuin — searchable, syncable shell history (replaces Ctrl-R when active)
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# ----------------------------------------------------------------------------
# Plugins — sourced directly from the Homebrew prefix; no plugin manager.
# Order matters: syntax-highlighting must be sourced LAST.
# ----------------------------------------------------------------------------
if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  _p="${HOMEBREW_PREFIX}/share/zsh-navigation-tools/zsh-navigation-tools.plugin.zsh"
  [[ -f "${_p}" ]] && source "${_p}"

  # Suggest commands from history as you type (accept with →)
  _p="${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "${_p}" ]] && source "${_p}"

  # ↑/↓ search history filtered by what you've typed
  _p="${HOMEBREW_PREFIX}/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  if [[ -f "${_p}" ]]; then
    source "${_p}"
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
  fi

  # Fish-style syntax highlighting (keep last)
  _p="${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  [[ -f "${_p}" ]] && source "${_p}"
  unset _p
fi

# ----------------------------------------------------------------------------
# Prompt — Starship (configured in ~/.config/starship.toml). Keep last.
# ----------------------------------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"
