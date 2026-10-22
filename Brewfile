# ============================================================================
# Brewfile — single source of truth for every package on this machine.
#
# Applied by scripts/brew.sh one entry at a time (announce → install →
# confirm, with progress) and filtered by the interactive selection screen.
# Inline comments double as the explanations shown in that screen.
# Organized into:
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
brew "starship"  # pretty, fast shell prompt (git branch, language versions)
brew "zoxide"    # smarter cd — 'z proj' jumps to your most-used folders
brew "fzf"       # fuzzy finder — Ctrl-R searches history, Ctrl-T finds files
brew "eza"       # nicer 'ls' with colors, icons, and git status
brew "bat"       # nicer 'cat' with syntax highlighting
brew "fd"        # faster, friendlier 'find'
brew "ripgrep"   # much faster 'grep' for searching code
brew "jq"        # query/format JSON on the command line
brew "yq"        # query/format YAML on the command line
brew "tree"      # print directory trees
brew "wget"      # download files from the terminal
brew "atuin"     # searchable shell history, synced across machines
brew "btop"      # pretty CPU/RAM/network monitor
brew "htop"      # classic process viewer
brew "tmux"      # split the terminal into panes; sessions survive disconnects
brew "fastfetch" # show system info with a logo
brew "neovim"    # modern vim editor

# zsh plugins — sourced directly from the brew prefix in dotfiles/.zshrc,
# no plugin manager needed.
brew "zsh-autosuggestions"          # ghost-text suggestions from your history as you type (→ accepts)
brew "zsh-syntax-highlighting"      # colors your command green when valid, red when not
brew "zsh-history-substring-search" # type part of a command, ↑/↓ finds matching history
brew "zsh-navigation-tools"         # interactive directory, process and history navigation

# ----------------------------------------------------------------------------
# 2. Formulae — utilities & code quality
# ----------------------------------------------------------------------------
brew "mas"        # Mac App Store CLI (needed by section 5)
brew "shellcheck" # shell script linter (used by this repo's CI)
brew "shfmt"      # shell script formatter
brew "railway"    # Railway CLI; authenticate separately
brew "supabase"   # Supabase CLI; authenticate separately
brew "stripe-cli" # Stripe CLI; authenticate separately

# ----------------------------------------------------------------------------
# 3. Casks — development
# ----------------------------------------------------------------------------
cask "visual-studio-code" # primary editor
cask "antigravity"        # Google Antigravity IDE (agent-first IDE)
cask "docker-desktop"     # Docker Desktop (bundles Compose & Buildx)
cask "postman"            # API client
cask "figma"              # design
cask "sf-symbols"         # Apple SF Symbols browser
cask "github"             # GitHub Desktop
cask "codex"              # OpenAI Codex CLI (distributed as a cask)
cask "claude-code"        # Anthropic Claude Code CLI
cask "1password-cli"      # 1Password command-line tools

# ----------------------------------------------------------------------------
# 3. Casks — browsers & AI assistants
# ----------------------------------------------------------------------------
cask "google-chrome" # primary browser
cask "chatgpt"       # OpenAI ChatGPT desktop
cask "claude"        # Anthropic Claude desktop
cask "blender"       # 3D modelling and animation
cask "inkscape"      # vector illustration

# ----------------------------------------------------------------------------
# 3. Casks — productivity & communication
#
# Apps that also exist on the Mac App Store live in section 5 instead (one
# source per app — two sources is how duplicate copies happen). Teams,
# WhatsApp, and The Unarchiver moved there for exactly that reason.
# ----------------------------------------------------------------------------
cask "notion"       # notes & docs workspace
cask "obsidian"     # local-first Markdown notes
cask "discord"      # voice & text communities
cask "google-drive" # Google Drive file sync
cask "libreoffice"  # free office suite — open/edit Word, Excel, PowerPoint files

# ----------------------------------------------------------------------------
# 3. Casks — utilities
# ----------------------------------------------------------------------------
cask "appcleaner"    # clean app uninstalls
cask "caffeine"      # keep the Mac awake
cask "1password"     # current 1Password desktop; App Store listing is legacy v7
cask "bettertouchtool" # configurable input gestures (licence required)
cask "keyboardcleantool" # temporarily disable the keyboard for cleaning
cask "anydesk"       # remote desktop; grant permissions yourself
cask "teamviewer"    # remote support; grant permissions yourself
cask "zoom"          # video meetings
cask "dropbox"       # Dropbox file sync
cask "obs"           # OBS Studio recording and streaming
cask "transmission"  # BitTorrent client
cask "daisydisk"     # disk usage visualizer (cask on purpose: the App Store build is sandboxed and can't clean everything)
cask "logi-options+" # Logitech mouse/keyboard configuration
cask "vlc"           # media player that opens anything

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
cask "steam"   # game library
cask "stremio" # streaming media hub

# ----------------------------------------------------------------------------
# 4. Fonts
# ----------------------------------------------------------------------------
cask "font-jetbrains-mono"           # primary coding font
cask "font-jetbrains-mono-nerd-font" # same font + icons for the terminal prompt

# Recommended additions — uncomment to install:
# cask "font-fira-code"      # classic ligature font
# cask "font-monaspace"      # GitHub's texture-healing font family
# cask "font-geist-mono"     # Vercel's mono font
# cask "font-cascadia-code"  # Microsoft's terminal font

# ----------------------------------------------------------------------------
# 5. Mac App Store (requires being signed in to the App Store)
#    Paid apps must already be purchased with your Apple ID; otherwise they
#    are routed to the manual-actions report by scripts/mas.sh.
#
#    POLICY: when an app exists both as a cask and on the Mac App Store, it
#    lives HERE (App Store wins) — installing from two sources is how you
#    end up with two copies of Teams/WhatsApp. Known exception: DaisyDisk
#    (section 3), whose App Store build is limited.
# ----------------------------------------------------------------------------
mas "Pages", id: 361309726          # Apple word processor (universal listing)
mas "Numbers", id: 361304891        # Apple spreadsheets (universal listing)
mas "Keynote", id: 361285480        # Apple presentations (universal listing)
mas "Shazam", id: 897118787         # identify songs from the menu bar
mas "Swift Playground", id: 1496833156 # learn/prototype Swift
mas "TestFlight", id: 899247664     # beta-test iOS/macOS apps
mas "Developer", id: 640199958      # Apple developer news & WWDC
mas "ColorSlurp", id: 1287239339    # color picker
mas "Final Cut Pro", id: 424389933  # video editing (paid)
mas "Compressor", id: 424390742     # Final Cut export encoder (paid)
mas "DaVinci Resolve", id: 571213070 # video editing
mas "Logic Pro", id: 634148309     # music production (paid)
mas "Motion", id: 434290957        # motion graphics (paid)
mas "Photomator", id: 1444636541   # photo editing (in-app purchase)
mas "Slack", id: 803453959         # team messaging
mas "OneDrive", id: 823766827      # Microsoft file sync
mas "Tailscale", id: 1475387142    # private networking; sign in separately
mas "Termius", id: 1176074088      # SSH client
mas "Canva", id: 897446215         # visual design (universal listing)
# NOT installed/enabled: TeamsTxNDI, Teams' built-in NDI production/broadcast
# add-on that streams a meeting's audio/video to OBS/vMix over the local
# network. It's a Teams-internal opt-in feature (Settings → App permissions →
# Production tools), not a separate Homebrew cask or App Store listing, so
# there's nothing to tick here — just don't turn it on inside Teams.
mas "Microsoft Teams", id: 1113153706 # work chat & meetings (App Store)
mas "WhatsApp", id: 310633997       # WhatsApp Messenger (native Mac app)
mas "The Unarchiver", id: 425424353 # archive extraction

# Xcode is intentionally NOT here — scripts/xcode.sh manages it (CLT first,
# license acceptance, xcode-select) so ordering is correct.
