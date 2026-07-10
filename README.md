# mac-setup

> One command turns a brand-new Mac into my complete development workstation.

```bash
curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
```

Run that, and mac-setup introduces itself, shows a **tick-list of everything
it can install** (apps, terminal tools, setup steps — each with a one-line
explanation), lets you untick what you don't want, asks for one confirmation,
and then runs autonomously with a live *"34 of 72 installed · 38 to go"*
progress readout.

New here? The friendly walkthrough lives on the
**[landing page](https://pedrobritx.github.io/mac-setup/)**.

`mac-setup` is an Infrastructure-as-Code project, not a shell script pile:
modular, idempotent, logged, verifiable, and safe to run as many times as you
like. Running it twice never breaks anything — everything already satisfied is
detected and skipped.

## Overview

A fresh macOS install is hours of clicking: App Store, DMGs, `defaults write`
incantations, dotfiles, SSH keys, IDE settings. This repository captures all
of it as version-controlled code. When a machine dies, gets replaced, or gets
wiped, restoring it is: clone → one command → coffee.

**Design principles**

- **Stock-first, performance above all** — window management, Mission
  Control, Spaces, and animations are **never** overridden. The Mac keeps its
  brand-new feel; the only defaults written are small functional preferences
  (typing, tap-to-click, Finder navigation). Legacy overrides from older
  versions are actively deleted.
- **You choose, then it runs** — an interactive selection screen before
  anything happens; one confirmation; then fully autonomous with per-item
  progress. Transparent throughout: it says what it *will* do, what it *is*
  doing, and what it *has* done.
- **One source per app** — when an app exists on the Mac App Store, it
  installs from there, not from a cask (two sources is how you end up with
  two copies of Teams/WhatsApp). A guard also skips any cask whose app is
  already installed. Documented exception: DaisyDisk stays on Homebrew — the
  App Store build is sandboxed and limited.
- **Idempotent** — every action is guarded by a check; re-runs are no-ops.
- **Single source of truth** — all packages live in one annotated [`Brewfile`](Brewfile).
- **Prefer official channels** — Homebrew → Mac App Store (`mas`) → official
  CLI → manual instructions. Never unofficial mirrors.
- **Fail soft, report loud** — one broken cask never sinks the run; anything
  that needs a human lands in a manual-actions report with URL + steps.
- **Reversible** — pre-existing dotfiles are backed up before linking;
  `uninstall.sh` removes exactly what was installed, never user files.

## Features

- ✅ **Interactive selection** — tick/untick every app, tool, and setup step
  before anything installs; per-item explanations; choices remembered
- 📊 **Live progress** — each item announced and confirmed, with a running
  `[X/Y · Z to go]` counter across the whole run
- 🍺 **Homebrew bootstrap** for ~40 formulae, ~20 casks, fonts — installed
  one by one so a single bad package never blocks the rest
- 🛍️ **Mac App Store** automation via `mas` (Pages, Final Cut Pro, Teams,
  WhatsApp, …) — preferred over casks when an app exists in both, so you
  never get two copies of the same app
- 🛠️ **Toolchains**: Node (via **fnm**), pnpm, bun, Python (via **uv**), pipx,
  Swift + SwiftFormat/SwiftLint, Docker Desktop (installed, but only launched
  when you need it — no always-on daemon eating battery)
- 💻 **Terminal**: zsh + Starship prompt + autosuggestions, syntax highlighting,
  fzf, zoxide, atuin, eza, bat, ripgrep — no framework, startup stays fast
- 🔑 **Git & SSH**: identity, Ed25519 key (never overwrites), SSH commit
  signing, Git LFS, GitHub CLI auth
- ⚙️ **macOS defaults**: minimal and stock-first — keyboard, tap-to-click,
  Finder path bar, screenshot folder, Safari Develop menu. Hidden files stay
  hidden (`⌘⇧.` when needed); window management and animations stay stock
- 📁 **Directory layout**: `~/Developer/{Personal,Clients,OpenSource,…}`,
  `~/Screenshots`, `~/Downloads/Installers`
- 🧪 **Verification**: `./verify.sh` checks every layer and prints a colored
  scorecard; CI lints every script with ShellCheck
- 📋 **Reports**: install report, verification report, and a manual-actions
  report for the few things Apple/vendors won't let us automate

## Repository structure

```
mac-setup/
├── bootstrap.sh          # curl-able entry point (CLT → clone → install.sh)
├── install.sh            # orchestrator: runs modules in dependency order
├── update.sh             # brew/mas/extensions/toolchains updates + cleanup
├── verify.sh             # verification scorecard (wraps scripts/verification.sh)
├── cleanup.sh            # cache & state pruning
├── uninstall.sh          # removes what this repo installed — nothing else
├── Brewfile              # ALL packages: taps, formulae, casks, fonts, mas
├── config/
│   └── settings.sh       # the one file to personalize (identity, dirs, …)
├── lib/                  # shared foundation (sourced by everything)
│   ├── common.sh         #   paths, platform detection, guards
│   ├── log.sh            #   colored leveled logging → terminal + file
│   ├── run.sh            #   dry-run wrapper, retries, backups, symlinks
│   ├── checks.sh         #   idempotency predicates
│   ├── picker.sh         #   interactive "tick what to install" screen
│   ├── progress.sh       #   "X of Y installed · Z to go" counters
│   └── report.sh         #   OK/SKIP/FAIL/MANUAL accumulation + rendering
├── scripts/              # one module per concern (run standalone or via install.sh)
│   ├── xcode.sh brew.sh apps.sh mas.sh
│   ├── git.sh ssh.sh terminal.sh node.sh python.sh swift.sh
│   ├── vscode.sh macos.sh security.sh
│   └── directories.sh verification.sh
├── dotfiles/             # symlinked into $HOME (originals are backed up)
│   ├── .zshrc .zprofile
│   ├── .config/zsh/      #   aliases.zsh functions.zsh exports.zsh
│   ├── .config/starship.toml
│   ├── .config/git/      #   config + global ignore
│   └── vscode/           #   settings.json, extensions.txt, snippets/
├── assets/               # wallpapers, icons
└── docs/                 # INSTALL, POST_INSTALL, TROUBLESHOOTING, ARCHITECTURE
    └── index.html        # the landing page (GitHub Pages)
```

## Installation

### The one command (new Mac)

```bash
curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
```

That installs the Xcode Command Line Tools, clones this repo to
`~/Developer/mac-setup`, and starts the install:

1. **Pick** — a checklist of every app, tool, and setup step (with
   explanations). `↑`/`↓` moves, `space` ticks/unticks, `a` toggles a whole
   group, `enter` continues. Everything starts ticked; your unticks are
   remembered for next time.
2. **Confirm** — a per-group summary plus exactly what will be skipped,
   then one `y` to proceed.
3. **Relax** — the rest runs by itself, announcing each item before, during,
   and after, with a running `[34/72 · 38 to go]` counter. You may be asked
   for your password (sudo) and App Store sign-in along the way.

Prefer no questions at all? `./install.sh --yes` installs everything.

### From a clone

```bash
git clone https://github.com/pedrobritx/mac-setup.git ~/Developer/mac-setup
cd ~/Developer/mac-setup
./install.sh
```

### Useful flags

```bash
./install.sh --yes                 # install everything; skip the selection screen
./install.sh --dry-run             # preview everything; change nothing
./install.sh --list                # list all modules
./install.sh --only brew,apps      # run specific modules (skips the selection screen)
./install.sh --skip macos          # run everything except system defaults
./install.sh --verbose             # debug output
```

See [docs/INSTALL.md](docs/INSTALL.md) for the full walkthrough and
[docs/POST_INSTALL.md](docs/POST_INSTALL.md) for the (short) list of manual
follow-ups.

## Updating

```bash
cd ~/Developer/mac-setup && ./update.sh
```

Pulls the latest repo, updates Homebrew and every package/cask, installs new
Brewfile entries, upgrades App Store apps, VS Code extensions, and toolchains,
cleans caches, and reports anything still outdated.

## Verification & reports

```bash
./verify.sh
```

Prints a colored scorecard covering brew, git, node, python, swift,
fonts, apps, terminal plugins, and dotfile links. Every run of `install.sh`
also writes reports to `~/.local/state/mac-setup/reports/`:

| Report | Contents |
|--------|----------|
| `install-report.md` | every action: installed / skipped / failed |
| `verification-report.md` | the full scorecard |
| `manual-actions.md` | items needing a human, with official URL + steps |

Logs live in `~/.local/state/mac-setup/logs/`.

## Customization

- **Add an app** — add a `cask`/`brew`/`mas` line to the [`Brewfile`](Brewfile)
  and run `./install.sh` (or `./update.sh`).
- **Remove an app** — delete its line, then
  `brew bundle cleanup --file=Brewfile` (add `--force` to actually uninstall).
- **Identity & directories** — edit [`config/settings.sh`](config/settings.sh).
- **Shell** — edit `dotfiles/.config/zsh/{aliases,functions,exports}.zsh`;
  changes apply instantly because the files are symlinked.
- **macOS defaults** — tweak `scripts/macos.sh`; every write is one documented
  `defaults_write` line. Keep the rule in that file's header in mind: nothing
  that touches window management, Mission Control, or animations.
- **VS Code** — capture your extensions with
  `code --list-extensions > dotfiles/vscode/extensions.txt`.

Details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Troubleshooting

Common fixes live in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).
The short version: re-run `./install.sh` (it's idempotent), check the log in
`~/.local/state/mac-setup/logs/`, and run a single module with
`./install.sh --only <module> --verbose`.

## FAQ

**Is it safe to run twice?** Yes — that's the core design constraint. Every
action checks state first; satisfied actions are skipped.

**Will it overwrite my dotfiles or SSH keys?** No. SSH keys are never touched
if present. Existing dotfiles are backed up to
`~/.local/state/mac-setup/backups/<run>/` before linking, and `uninstall.sh`
restores them.

**Why fnm/uv instead of nvm/pyenv+pip?** Speed and simplicity — see
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#tool-choices).

**Why isn't app X installing?** If it has no Homebrew cask or App Store
listing (e.g. Cisco Secure Client), it's in `manual-actions.md` with the
official URL and steps.

**Does this work on Intel Macs?** Yes — the Homebrew prefix
(`/opt/homebrew` vs `/usr/local`) is detected automatically.

## Contributing

This is a personal setup, but PRs and issues are welcome — see
[CONTRIBUTING.md](CONTRIBUTING.md). All shell code must pass ShellCheck and
`shfmt` (CI enforces both).

## Roadmap

- [ ] Machine profiles (personal vs work) selecting Brewfile subsets
- [ ] `defaults` diff tool: capture current settings back into the repo
- [ ] Nightly scheduled `verify.sh` with notification on drift
- [ ] Time Machine / restic backup bootstrap

## License

[MIT](LICENSE)
