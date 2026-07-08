# aliases.zsh — organized aliases (managed by mac-setup).
# Modern-tool aliases are guarded so a missing tool falls back to the classic.

# --- Navigation -------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dev='cd ~/Developer'
alias dl='cd ~/Downloads'
alias ws='cd ~/Workspace'

# --- Listing (eza) -----------------------------------------------------------
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --git'
  alias la='eza -la --group-directories-first --git'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

# --- Modern replacements ------------------------------------------------------
command -v bat >/dev/null && alias cat='bat --paging=never'
command -v fd >/dev/null && alias find='fd'
command -v rg >/dev/null && alias grep='rg'
command -v nvim >/dev/null && alias vim='nvim' && alias vi='nvim'

# --- Git ---------------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gsw='git switch'

# --- Homebrew / system --------------------------------------------------------
alias brewup='brew update && brew upgrade && brew cleanup'
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder'

# --- Networking ----------------------------------------------------------------
alias ip='curl -s https://ifconfig.me && echo'
alias localip="ipconfig getifaddr en0"
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'

# --- Docker ---------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# --- Safety nets -----------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
