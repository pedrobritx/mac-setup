# mac-setup

> One command turns a brand-new Mac into my complete development workstation.

```bash
curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
```

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

- **Idempotent** — every action is guarded by a check; re-runs are no-ops.
- **Single source of truth** — all packages live in one annotated [`Brewfile`](Brewfile).
- **Prefer official channels** — Homebrew → Mac App Store (`mas`) → official
  CLI → manual instructions. Never unofficial mirrors.
- **Fail soft, report loud** — one broken cask never sinks the run; anything
  that needs a human lands in a manual-actions report with URL + steps.
- **Reversible** — pre-existing dotfiles are backed up before linking;
  `uninstall.sh` removes exactly what was installed, never user files.

## Features

- 🍺 **Homebrew bootstrap** + `brew bundle` for ~40 formulae, ~25 casks, fonts
- 🛍️ **Mac App Store** automation via `mas` (Pages, Final Cut Pro, TestFlight, …)
- 🛠️ **Toolchains**: Node (via **fnm**), pnpm, bun, Python (via **uv**), pipx,
  Swift + SwiftFormat/SwiftLint, Docker Desktop (verified with `hello-world`)
- 💻 **Terminal**: zsh + Starship prompt + autosuggestions, syntax highlighting,
  fzf, zoxide, atuin, eza, bat, ripgrep — no framework, startup stays fast
- 🔑 **Git & SSH**: identity, Ed25519 key (never overwrites), SSH commit
  signing, Git LFS, GitHub CLI auth
- ⚙️ **macOS defaults**: Finder, Dock, keyboard, trackpad, screenshots,
  Safari developer mode — applied only when values differ
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
│   └── report.sh         #   OK/SKIP/FAIL/MANUAL accumulation + rendering
├── scripts/              # one module per concern (run standalone or via install.sh)
│   ├── xcode.sh brew.sh apps.sh mas.sh fonts.sh
│   ├── git.sh ssh.sh terminal.sh node.sh python.sh swift.sh docker.sh
│   ├── vscode.sh macos.sh finder.sh dock.sh security.sh
│   └── directories.sh downloads.sh verification.sh
├── dotfiles/             # symlinked into $HOME (originals are backed up)
│   ├── .zshrc .zprofile
│   ├── .config/zsh/      #   aliases.zsh functions.zsh exports.zsh
│   ├── .config/starship.toml
│   ├── .config/git/      #   config + global ignore
│   └── vscode/           #   settings.json, extensions.txt, snippets/
├── assets/               # wallpapers, icons
└── docs/                 # INSTALL, POST_INSTALL, TROUBLESHOOTING, ARCHITECTURE
```

## Installation

### The one command (new Mac)

```bash
curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
```

That installs the Xcode Command Line Tools, clones this repo to
`~/Developer/mac-setup`, and runs the full install.

### From a clone

```bash
git clone https://github.com/pedrobritx/mac-setup.git ~/Developer/mac-setup
cd ~/Developer/mac-setup
./install.sh
```

### Useful flags

```bash
./install.sh --dry-run             # preview everything; change nothing
./install.sh --list                # list all modules
./install.sh --only brew,fonts     # run specific modules
./install.sh --skip macos,dock     # run everything except system defaults
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

Prints a colored scorecard covering brew, git, node, python, swift, docker,
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
- **macOS defaults** — tweak `scripts/macos.sh`, `finder.sh`, `dock.sh`; every
  write is one documented `defaults_write` line.
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
- [ ] Dock layout management via `dockutil`
- [ ] Nightly scheduled `verify.sh` with notification on drift
- [ ] Time Machine / restic backup bootstrap

## License

[MIT](LICENSE)
