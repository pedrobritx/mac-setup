# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed — performance overhaul (stock-first defaults)

The Mac's UI glitched after earlier versions ran (full-screen management,
Mission Control, window sizing, animation speed). Root cause: `defaults`
overrides in the window-management/animation area. This release adopts a
hard rule — **never override window management, Mission Control, Spaces,
hot corners, or animations** — and reorganizes the modules around it.

- `macos` module: now the single owner of every `defaults` write (the
  separate `finder` and `dock` modules are merged into it). It writes only
  minimal functional preferences (key repeat, text-substitution toggles,
  tap-to-click, Finder path bar/extensions/list view/search scope, Dock
  icon size, screenshot folder, Safari Develop menu, expanded save panels)
  and **deletes every legacy window/animation override** earlier versions
  wrote — hot corners, forced window tabbing, title-bar double-click Fill,
  Dock magnification/minimize effects, Mission Control and animation-speed
  hacks — restoring stock behavior on previously-tweaked machines.
- Finder: hidden files and the status bar are no longer enabled — both stay
  at the macOS default (off). The path bar stays on. Toggle hidden files on
  demand with `⌘⇧.` or the `showfiles`/`hidefiles` aliases.
- Safer stock behavior restored: Gatekeeper's open-confirmation for
  downloads (`LSQuarantine`), the extension-change warning, crash-report
  dialogs, and screenshot shadows are no longer overridden.
- Docker Desktop is still installed via the Brewfile but is never
  auto-launched — no always-on daemon on a fresh machine.

### Removed

- `finder` and `dock` modules (merged into `macos`); the
  `MAC_SETUP_ENABLE_DOCK` toggle.
- `docker` module (launched Docker Desktop at install time and ran
  `hello-world`); the docker-desktop cask remains in the Brewfile.
- `downloads` module (installer sweep gimmick); `~/Downloads/Installers` is
  still created by the `directories` module.
- `fonts` module (redundant — fonts are installed by the Brewfile and
  checked by `verification`).
- OnyX opportunistic install (system-maintenance tweakers are a common
  source of exactly the UI glitches this release eliminates).

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
  manual-action item) and `onyx` (see Removed above).
- `apps` module: calls `ensure_brew_in_path` so it no longer exits with
  status 1 when Homebrew was installed earlier in the same run and PATH has
  not been reloaded.
- `node`/`python` modules: self-heal by installing their prerequisites
  (fnm, pnpm, bun, uv, pipx) through Homebrew when the brew module missed
  them, instead of failing outright.
- `macos` module: Safari's sandboxed preferences are probed once; without
  Full Disk Access the three Safari writes become a single manual-action
  entry instead of repeated errors.
- `sudo` keep-alive: prompts on `/dev/tty` when the script is piped
  (`curl | bash`), so sudo no longer fails mid-run with
  "a password is required".

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
