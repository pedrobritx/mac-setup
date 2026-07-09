# Installation Guide

## Prerequisites

- A Mac running macOS 14 (Sonoma) or newer — Apple Silicon or Intel.
- An Apple ID (sign in to the App Store beforehand to automate Mac App Store
  installs; otherwise those apps land in the manual-actions report).
- An admin account. Do **not** run anything here as root — steps that need
  privileges ask for `sudo` themselves.

## Option A — the one command (recommended for a new Mac)

Open Terminal.app and run:

```bash
curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash
```

What happens, in order:

1. **Xcode Command Line Tools** — a system dialog appears; approve it.
   (Everything else depends on this, including `git`.)
2. The repository is **cloned to `~/Developer/mac-setup`**.
3. `install.sh` takes over and runs all modules (see below).

Expect 30–90 minutes on a fresh machine depending on network speed — Xcode
dominates. The run is fully resumable: if anything is interrupted, run it
again and completed steps are skipped.

## Option B — from a clone

```bash
git clone https://github.com/pedrobritx/mac-setup.git ~/Developer/mac-setup
cd ~/Developer/mac-setup
./install.sh
```

## Before you run: personalize

Edit [`config/settings.sh`](../config/settings.sh) — git identity, GitHub
username, directory layout, Node/Python versions. Every value can also be
passed as an environment variable for a one-off:

```bash
MAC_SETUP_GIT_EMAIL="work@example.com" ./install.sh --only git
```

## What runs, in order

| # | Module | What it does |
|---|--------|--------------|
| 1 | `xcode` | Command Line Tools, optional full Xcode, license, `xcode-select` |
| 2 | `brew` | Homebrew install/update, `brew bundle` (everything in the Brewfile) |
| 3 | `directories` | `~/Developer/…`, `~/Workspace`, `~/Screenshots`, `~/Downloads/Installers` |
| 4 | `apps` | Reconciles casks; reports non-automatable apps |
| 5 | `mas` | Reconciles App Store apps; reports unpurchased ones |
| 6 | `ssh` | Ed25519 key (only if missing), agent + keychain, GitHub guidance |
| 7 | `git` | Identity, defaults, LFS, SSH commit signing, `gh` auth |
| 8 | `terminal` | Links zsh/Starship dotfiles, verifies tools & plugins |
| 9 | `node` | Node LTS via fnm, corepack, pnpm, bun |
| 10 | `python` | Python via uv, pipx PATH |
| 11 | `swift` | Verifies Swift; SwiftFormat/SwiftLint |
| 12 | `vscode` | Links settings/snippets, installs extensions |
| 13 | `macos` | Minimal stock-first defaults; deletes legacy window/animation overrides |
| 14 | `security` | Firewall, Touch ID for sudo, screen lock, FileVault status |
| 15 | `verification` | Full scorecard + report |

Deliberately **absent**: any module that overrides window management,
Mission Control, hot corners, or animation speed. Docker Desktop is
installed by the Brewfile but never auto-launched — start it the first time
you actually need containers.

## Partial runs

```bash
./install.sh --list                 # see all modules
./install.sh --only terminal        # one module
./install.sh --only brew,vscode     # several
./install.sh --skip macos           # all except
./install.sh --dry-run              # print, don't do — works with all of the above
```

Every module is also directly executable: `bash scripts/terminal.sh`.

## After the install

1. **Restart your terminal** (or log out/in) so PATH, prompt, and plugins load.
2. Read `~/.local/state/mac-setup/reports/manual-actions.md` — the few
   things that need a human (App Store sign-in, Cisco VPN, FileVault, …).
3. See [POST_INSTALL.md](POST_INSTALL.md) for the checklist.
4. Run `./verify.sh` whenever you want to re-check the machine.

## Recovery / re-run semantics

`install.sh` is safe to re-run at any point — after a failure, an
interruption, or six months later. State checks make completed work a no-op,
and the newest log in `~/.local/state/mac-setup/logs/` tells you exactly
where a failed run stopped and why.
