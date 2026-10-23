# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed — languages and softer window motion

- Added a keyboard-operable round flag picker for English (UK), Brazilian
  Portuguese, French, German and Spanish (Spain). Bundled translations cover the
  setup flow, catalogue descriptions and Safety page; language persists locally.
- Extended catalogue search to translated descriptions, preserved canonical plan
  IDs and commands, and added translation completeness/interpolation checks.
- Balanced sidebar import/reset padding, matched the whole setup window's spring
  to the floating navigation, and kept the compact summary outside its moving
  container. Spread and dimmed the cursor-following highlights.

### Changed — cohesive Fluid interactions and participation

- Renamed the appearance control to Fluid and extended rounded hover/focus bodies
  and elastic surface response across navigation, secondary, back and text actions.
  Added subtler window/titlebar response, native-scroll elastic shading and
  hover-only animated gradient headings; accessibility preferences still win.
- Replaced the native source popup with a keyboard-operable glass listbox that
  flips above the floating summary when needed. Added dependency-aware category
  selection, including choices hidden by filters, with persistent focus.
- Added genuine local app artwork and brand icons for 88 catalogue entries,
  with source/checksum provenance and symbol fallbacks. No remote icon lookup runs
  in the browser.
- Added a visual three-step guide, fixed circular close geometry, backdrop
  dismissal and explicit opener focus restoration.
- Added a Safety & privacy page, GitHub/LinkedIn creator credits, Buy Me a Coffee,
  and prefilled GitHub suggestion/problem links. Extended only the exact public
  HTML allowlist; private local APIs remain authenticated.

### Changed — Liquid Acrylic browser interface

- Restored the original mint/blue/lilac identity with a generated aurora wallpaper,
  gradient headings, floating translucent toolbar and rounded Mac window chrome.
- Added spring-driven, shared liquid silhouettes for profiles and categories,
  pointer-following sheen, deforming button surfaces, drawn checkbox checks,
  smooth view navigation and Transitions.dev modal motion.
- Added a persistent Calm appearance and system motion/transparency fallbacks.
  Native controls and immediate Escape dismissal preserve keyboard operation.
- Retained catalogue controls during selection updates and preserved focus after
  category changes and selected-chip removal. Browser plans and local installation
  boundaries are unchanged.

### Added — guided browser setup

- Static, responsive setup workspace with Essentials, Developer, Education,
  Productivity, Creative and BRITX Choice profiles; editable selections,
  category/source/search filters, local persistence, JSON import/export and review.
- Python standard-library local companion with explicit confirmation, real module
  progress, installer output, downloadable reports and official manual/MCP guides.
  No hosted backend or Node dependency is needed to run the interface.
- Validated `install.sh --selection FILE` path. Explicit selections leave unrelated
  packages alone, respect declined preferences, and verify only chosen components.
- Requested desktop and CLI additions, App Store creative apps, current universal
  Apple office listings, and App Store sources for Slack, Canva, OneDrive,
  Tailscale and Termius. Codex now uses its supported Homebrew cask.
- Optional Oh My Zsh alongside the existing Starship prompt and Homebrew plugins.
- Catalogue drift checks, selection/API/security tests, isolated installer tests,
  and WebKit workflow/responsive/accessibility checks.
- Shared Git identity defaults are blank; local review supplies the installer's
  own identity without putting it in an exported plan.

### Added — choose-what-you-install

- **Interactive selection screen** (`lib/picker.sh`): a full run now starts
  with a tick-list of every app, terminal tool, and setup step — grouped,
  each with a one-line explanation parsed from the Brewfile comments
  (the zsh plugins finally explain themselves). `↑/↓` move, `space` ticks,
  `a` toggles a group, `enter` reviews, one `y` confirms, then the run is
  fully autonomous. Works through `curl | bash` (reads `/dev/tty`).
  Unticks are remembered across runs. `--yes`, `--only`, `--skip`, and
  CI/no-TTY runs bypass it.
- **Live progress** (`lib/progress.sh`): every package is announced,
  installed, and confirmed with a running `[X/Y · Z to go]` counter across
  the brew, apps, and mas modules; the final summary reports how many of
  the selected items are on the machine.
- **Per-category macOS & security suggestions in the picker:** the coarse
  "macOS defaults" and "Security" steps are replaced by individual ticket
  items — Keyboard, Tap to click, Finder tweaks, Dock icon size, Screenshots,
  Safari Develop menu, Expanded panels, Application firewall, Touch ID for
  sudo, Immediate screen lock. Each is a suggestion (ticked by default) you
  can untick; choices are exported as `MAC_SETUP_PREF_<CATEGORY>` and applied
  autonomously — no mid-run prompts. Staying stock-first, window management,
  Mission Control, magnification and animations are never offered, and
  `remove_legacy_overrides` always runs. Pin any category ahead of time in
  `config/settings.sh` (or the environment) for `--only`/`--yes`/CI runs; a
  category left unset applies, so plain runs still converge on the favourite
  config. New helper `pref_enabled` (lib/run.sh) resolves the choice.
- **Landing page** (`docs/index.html`): a friendly GitHub Pages site with
  the install command and a short tutorial for non-technical users.
- **"Britx choice" favourites profile** (`config/britx-choice.sh`,
  `picker_apply_britx` in `lib/picker.sh`): a second, smaller personalization
  file listing apps/tools/steps/preferences to leave unticked
  (`MAC_SETUP_BRITX_EXCLUDE`) — everything else in the catalog is ticked.
  Press `b` on the selection screen to jump to it (still reviewable before
  confirming), or run `./install.sh --britx` for a fully unattended install
  of the same selection.
- `Brewfile`: added `libreoffice` (free office suite) to the productivity
  casks.

### Changed — apps & install flow

- Replaced the `chatgpt-atlas` cask with `google-chrome`.
- **One source per app:** Microsoft Teams, WhatsApp, and The Unarchiver
  moved from casks to the Mac App Store section (the App Store wins when an
  app exists in both — two sources is how duplicate copies of Teams and
  WhatsApp appeared). A new duplicate-copy guard (`cask_app_name` +
  `app_installed`) also skips any cask whose `.app` already exists.
  Documented exception: DaisyDisk stays a cask (the App Store build is
  sandboxed/limited).
- `brew` module installs packages **one at a time** instead of one big
  `brew bundle` — per-item announce/confirm with progress, and a single bad
  entry never blocks the rest.

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
- **Selections are now actually respected end-to-end.** The `node`, `python`,
  `terminal`, and `swift` modules previously ignored the picker: unticking a
  formula (e.g. `fnm`, `uv`, `pipx`, `btop`, `swiftformat`, a zsh plugin)
  still self-healed it via `ensure_brew_formula`, or reported it as a FAILURE
  in the summary even though it was intentionally skipped. New helper
  `brewfile_formula_selected` (`lib/checks.sh`) checks the active Brewfile
  first, so an unticked formula is now skipped (and reported as skipped),
  never reinstalled or misreported as broken. On the non-interactive paths
  (`--yes`, `--only`, `--skip`, CI) `$MAC_SETUP_BREWFILE` is the full repo
  Brewfile, so the check is always true there and behavior is unchanged.
- Brewfile / docs: documented that mac-setup never installs or enables
  TeamsTxNDI, Microsoft Teams' built-in NDI production/broadcast add-on —
  it's a Teams-internal opt-in feature, not a separate package, so there was
  nothing to actually exclude at the package-manager level.

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
