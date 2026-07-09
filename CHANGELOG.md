# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- `brew` module: taps declared in the Brewfile are now tapped **and trusted**
  before `brew bundle` runs — Homebrew 6 refuses untrusted third-party taps
  (`oven-sh/bun`), which previously aborted the whole bundle.
- `brew` module: when `brew bundle` fails (its fetch is all-or-nothing), the
  module now falls back to installing every Brewfile formula and cask
  individually, skipping anything already installed, so a single bad entry
  can no longer block every other package.
- Brewfile: removed `vmware-fusion` (cask deleted from homebrew/cask after
  Broadcom moved distribution to its support portal — it is now a
  manual-action item) and `onyx` (frequently incompatible with new macOS
  releases — now installed opportunistically by the apps module).
- `apps`/`fonts` modules: call `ensure_brew_in_path` so they no longer exit
  with status 1 when Homebrew was installed earlier in the same run and PATH
  has not been reloaded.
- `node`/`python` modules: self-heal by installing their prerequisites
  (fnm, pnpm, bun, uv, pipx) through Homebrew when the brew module missed
  them, instead of failing outright.
- `macos` module: Safari's sandboxed preferences are probed once; without
  Full Disk Access the three Safari writes become a single manual-action
  entry instead of repeated errors.
- `sudo` keep-alive: prompts on `/dev/tty` when the script is piped
  (`curl | bash`), so sudo no longer fails mid-run with
  "a password is required".

### Changed

- `macos` module: Mission Control overrides (Space rearrangement, window
  grouping, Space auto-switching, animation speed) are now **removed** to
  restore stock macOS behavior — the previous tweaks made Mission Control
  feel fast and glitchy.
- `dock` module: Dock now stays visible (auto-hide off, speed hacks
  removed), icon size ≈ 20% with magnification ≈ 50%, suggested/recent apps
  shown, title-bar double-click set to Fill, tabs always preferred, and hot
  corners configured (Desktop, Notification Center, Application Windows,
  Quick Note) — matching the owner's documented System Settings.

## [1.0.0] - 2026-07-08

### Added

- Initial release: full Infrastructure-as-Code macOS bootstrap.
- `bootstrap.sh` — curl-able zero-to-workstation entry point.
- `install.sh` — module orchestrator with `--dry-run`, `--verbose`,
  `--only`, `--skip`, `--list`.
- Shared library (`lib/`) — logging, dry-run execution wrapper, idempotency
  checks, backups, symlink manifest, report rendering.
- `Brewfile` — single source of truth for taps, formulae, casks, fonts, and
  Mac App Store apps.
- 20 modules under `scripts/` covering Xcode, Homebrew, apps, MAS, fonts,
  git, SSH, terminal, Node (fnm), Python (uv), Swift, Docker, VS Code,
  macOS/Finder/Dock defaults, security, directories, downloads, and
  verification.
- Version-controlled dotfiles (zsh, Starship, git, VS Code) linked with
  automatic backups of pre-existing files.
- `update.sh`, `cleanup.sh`, `verify.sh`, `uninstall.sh` maintenance
  commands.
- Markdown reports: install report, verification report, manual-actions
  report; plain-text logs per run.
- Documentation: README, INSTALL, POST_INSTALL, TROUBLESHOOTING,
  ARCHITECTURE, CONTRIBUTING.
- CI: ShellCheck + shfmt + bash syntax check + dry-run smoke test.
