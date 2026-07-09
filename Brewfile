# ============================================================================
# Brewfile — single source of truth for every package on this machine.
#
# Applied by scripts/brew.sh via `brew bundle`. Organized into:
#   1. Taps        — third-party repositories
#   2. Formulae    — CLI tools and libraries
#   3. Casks       — GUI applications
#   4. Fonts       — cask-distributed fonts
#   5. Mac App Store — installed with `mas` (requires App Store sign-in)
#
# To ADD an app:    add a line here and run ./install.sh (or ./update.sh).
# To REMOVE an app: delete the line and run `brew bundle cleanup` (see docs).
#
# Not everything can live here — apps with no cask/mas entry (e.g. Cisco
# Secure Client) are handled by scripts/apps.sh and land in the
# manual-actions report.
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Taps
# ----------------------------------------------------------------------------
tap "oven-sh/bun" # official tap for the Bun runtime

# ----------------------------------------------------------------------------
# 2. Formulae — version control
# ----------------------------------------------------------------------------
brew "git"      # newer than the Apple-bundled git
brew "git-lfs"  # large file storage
brew "gh"       # GitHub CLI (auth, PRs, releases)

# ----------------------------------------------------------------------------
# 2. Formulae — languages & toolchains
# ----------------------------------------------------------------------------
brew "fnm"            # fast Node.js version manager (Rust; replaces nvm)
brew "pnpm"           # efficient Node package manager
brew "oven-sh/bun/bun" # Bun JS runtime & toolkit
brew "uv"             # Python package/version manager (replaces pyenv+pip)
brew "pipx"           # isolated installs for Python CLI tools
brew "swiftformat"    # Swift code formatter
brew "swiftlint"      # Swift linter

# ----------------------------------------------------------------------------
# 2. Formulae — data & media processing
# ----------------------------------------------------------------------------
brew "sqlite"      # embedded SQL database
brew "ffmpeg"      # audio/video swiss-army knife
brew "imagemagick" # image conversion & manipulation

# ----------------------------------------------------------------------------
# 2. Formulae — terminal environment
# ----------------------------------------------------------------------------
brew "starship"  # fast, minimal shell prompt
brew "zoxide"    # smarter cd
brew "fzf"       # fuzzy finder
brew "eza"       # modern ls
brew "bat"       # cat with syntax highlighting
brew "fd"        # modern find
brew "ripgrep"   # modern grep
brew "jq"        # JSON processor
brew "yq"        # YAML processor
brew "tree"      # directory trees
brew "wget"      # downloads
brew "atuin"     # shell history with sync & search
brew "btop"      # resource monitor
brew "htop"      # process viewer
brew "tmux"      # terminal multiplexer
brew "fastfetch" # system info
brew "neovim"    # editor

# zsh plugins — sourced directly from the brew prefix in dotfiles/.zshrc,
# no plugin manager needed.
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-history-substring-search"

# ----------------------------------------------------------------------------
# 2. Formulae — utilities & code quality
# ----------------------------------------------------------------------------
brew "mas"        # Mac App Store CLI (needed by section 5)
brew "shellcheck" # shell script linter (used by this repo's CI)
brew "shfmt"      # shell script formatter
brew "codex"      # OpenAI Codex CLI

# ----------------------------------------------------------------------------
# 3. Casks — development
# ----------------------------------------------------------------------------
cask "visual-studio-code" # primary editor
cask "antigravity"        # Google Antigravity IDE (agent-first IDE)
cask "docker-desktop"     # Docker Desktop (bundles Compose & Buildx)
cask "postman"            # API client
cask "figma"              # design
cask "sf-symbols"         # Apple SF Symbols browser

# ----------------------------------------------------------------------------
# 3. Casks — AI assistants
# ----------------------------------------------------------------------------
cask "chatgpt"       # OpenAI ChatGPT desktop
cask "chatgpt-atlas" # OpenAI Atlas browser
cask "claude"        # Anthropic Claude desktop

# ----------------------------------------------------------------------------
# 3. Casks — productivity & communication
# ----------------------------------------------------------------------------
cask "microsoft-teams"
cask "notion"
cask "obsidian"
cask "whatsapp"
cask "discord"
cask "google-drive"

# ----------------------------------------------------------------------------
# 3. Casks — utilities
# ----------------------------------------------------------------------------
cask "appcleaner"     # clean app uninstalls
cask "caffeine"       # keep the Mac awake
cask "daisydisk"      # disk usage visualizer
cask "logi-options+"  # Logitech peripherals
cask "the-unarchiver" # archive extraction
cask "vlc"            # media player

# NOT installed on purpose:
#   onyx          — dropped entirely. System-maintenance "tweakers" are a
#                   common source of the exact UI glitches this setup is
#                   designed to avoid; macOS needs no third-party cleaner.
#   vmware-fusion — removed from homebrew/cask after Broadcom moved
#                   distribution to its support portal; scripts/apps.sh
#                   records it as a manual action.

# ----------------------------------------------------------------------------
# 3. Casks — entertainment
# ----------------------------------------------------------------------------
cask "steam"
cask "stremio"

# ----------------------------------------------------------------------------
# 4. Fonts
# ----------------------------------------------------------------------------
cask "font-jetbrains-mono"           # primary coding font
cask "font-jetbrains-mono-nerd-font" # + icons for terminal/starship

# Recommended additions — uncomment to install:
# cask "font-fira-code"      # classic ligature font
# cask "font-monaspace"      # GitHub's texture-healing font family
# cask "font-geist-mono"     # Vercel's mono font
# cask "font-cascadia-code"  # Microsoft's terminal font

# ----------------------------------------------------------------------------
# 5. Mac App Store (requires being signed in to the App Store)
#    Paid apps must already be purchased with your Apple ID; otherwise they
#    are routed to the manual-actions report by scripts/mas.sh.
# ----------------------------------------------------------------------------
mas "Pages", id: 409201541
mas "Numbers", id: 409203825
mas "Keynote", id: 409183694
mas "Shazam", id: 897118787
mas "Swift Playground", id: 1496833156
mas "TestFlight", id: 899247664
mas "Developer", id: 640199958
mas "ColorSlurp", id: 1287239339
mas "Final Cut Pro", id: 424389933
mas "Compressor", id: 424390742

# Xcode is intentionally NOT here — scripts/xcode.sh manages it (CLT first,
# license acceptance, xcode-select) so ordering is correct.
