# Architecture

How mac-setup is built, and why.

## The mental model

```
bootstrap.sh ──▶ install.sh ──▶ scripts/<module>.sh   (one subprocess each)
 (curl-able)     (orchestrator)        │
                                       ▼
                          lib/  +  config/settings.sh  +  Brewfile
                        (shared foundation — sourced by every script)
```

- **`bootstrap.sh`** exists only to get from *nothing* to *a working clone*:
  Command Line Tools → clone → `exec ./install.sh`. It has no dependency on
  `lib/` because `lib/` doesn't exist yet on a fresh machine.
- **`install.sh`** owns ordering, flag parsing, sudo keep-alive, and report
  rendering. It executes each module as a **subprocess** (not `source`), so
  modules can't leak state into each other, a crashing module can't kill the
  orchestrator, and every module doubles as a standalone tool
  (`bash scripts/git.sh`).
- **Modules** share one skeleton: header comment → `source lib/common.sh` →
  documented functions → `main`. Cross-process context (dry-run flag, run id,
  log file, report file) travels through exported environment variables.

## The library

| File | Responsibility |
|------|----------------|
| `lib/common.sh` | repo/state paths, platform detection, guards; loads the rest |
| `lib/log.sh` | colored leveled logging; plain-text copy to the run's log file |
| `lib/run.sh` | `run` (the dry-run choke point), retries, backups, symlinking, `defaults_write`, confirmations |
| `lib/checks.sh` | pure predicates: `has_command`, `brew_cask_installed`, `app_installed`, `default_equals`, … |
| `lib/report.sh` | append-only TSV event stream → Markdown reports + terminal summary |

Two invariants make the whole system trustworthy:

1. **Every state change goes through `run` (or a helper built on it).**
   That single choke point implements `--dry-run` and debug logging for the
   entire codebase. A module that calls a mutating command directly is a bug.
2. **Every action is preceded by a `lib/checks.sh` predicate.** That is what
   makes re-runs no-ops — idempotency by construction, not by hope.

## Reports as a first-class output

Modules run in subprocesses, so results are accumulated in an append-only
TSV file (`~/.local/state/mac-setup/reports/<run>.tsv`) whose path is passed
down via the environment. Each record is `status ⇥ module ⇥ item ⇥ detail`
with `status ∈ {OK, SKIP, FAIL, MANUAL}`. At the end of a run the
orchestrator renders:

- **install-report.md** — the full ledger,
- **manual-actions.md** — every `MANUAL` record with official URL, the reason
  automation is impossible, and the exact steps,
- **verification-report.md** — written by `scripts/verification.sh`.

`MANUAL` is the key design decision: things that *cannot* be automated
(App Store sign-in, org-licensed Cisco VPN, FileVault's recovery-key choice)
are not failures — they're a to-do list the tool writes for you.

## The Brewfile is the package database

One annotated file declares taps, formulae, casks, fonts, and Mac App Store
apps. Modules never hardcode package lists; `apps.sh`, `mas.sh`, and
`verification.sh` all *parse the Brewfile* to know what should exist.
Adding an app is therefore a one-line change that automatically flows into
install, update, verify, and uninstall.

`brew bundle` does the bulk install; the per-domain modules then *reconcile*
— retrying individual failures and routing dead ends to the manual report.
This two-phase approach means one broken cask can't block fifty good ones.

## Stock-first macOS defaults

`scripts/macos.sh` is the **only** place `defaults` is written, and it obeys
one hard rule: *never override window management, Mission Control, Spaces,
hot corners, or animations.* Earlier versions of this repo (and most
"awesome macOS defaults" lists) tweaked exactly those — animation-duration
hacks, forced window tabbing, title-bar double-click actions, Dock
magnification, four hot corners — and the result was a Mac that glitched:
full-screen transitions stuttered, Mission Control misbehaved, windows
resized oddly.

The module therefore does two things:

1. **Deletes** every such override that earlier versions wrote (plus the
   classic offenders like `NSWindowResizeTime` and
   `expose-animation-duration`), restoring stock behavior on an
   already-tweaked machine. On a fresh machine these deletes are no-ops.
2. **Writes** only a small, purely functional set: key repeat and
   text-substitution toggles, tap-to-click, Finder path bar / extensions /
   list view / search scope, Dock icon size, screenshot folder, Safari's
   Develop menu, expanded save panels.

Hidden files and Finder's status bar deliberately stay off — `⌘⇧.` (or the
`showfiles`/`hidefiles` aliases) toggles hidden files on demand.

Adding a new `defaults_write` line? If it changes how windows, Spaces, or
animations behave, it doesn't belong here.

## Install-source policy

Homebrew → Mac App Store (`mas`) → official CLI installer → official DMG →
manual instructions. Higher sources win because they're scriptable,
checksummed, and updatable. Nothing is ever fetched from unofficial mirrors.

## Tool choices

| Chosen | Instead of | Why |
|--------|-----------|-----|
| **uv** | pyenv + pip + virtualenv | one Rust binary; 10-100× faster resolver; manages interpreters *and* packages; never touches system Python |
| **pipx** | global pip installs | each CLI tool in its own venv — no dependency clashes |
| **fnm** | nvm / brew node | instant startup (nvm adds ~500 ms per shell); respects `.nvmrc`/`.node-version`; versions stay out of brew's way |
| **Starship** | oh-my-zsh | prompt in Rust, config in one TOML file; oh-my-zsh drags a framework into every keystroke |
| plugins via brew | zinit/antigen/oh-my-zsh | three `source` lines; a plugin manager is a solution looking for a problem at this scale |
| **eza/bat/fd/ripgrep/zoxide** | ls/cat/find/grep/cd | quality-of-life; aliases degrade gracefully when absent |
| **atuin** | plain zsh history | searchable, syncable, per-directory history |
| Docker Desktop's bundled Compose | `docker-compose` formula | avoids version skew between engine and compose plugin |
| symlinked dotfiles | copied dotfiles | edits are instantly version-controlled; `git diff` shows config drift |

## Safety model

- **Never root.** `require_not_root` aborts; individual steps `sudo` only
  when needed, with one up-front keep-alive.
- **Never overwrite.** SSH keys are sacred (`generate_key` refuses if the
  file exists). Dotfiles are backed up to
  `~/.local/state/mac-setup/backups/<run>/` before linking.
- **Reversible.** Every symlink is recorded in a manifest;
  `uninstall.sh` removes exactly those links, restores backups, and only
  uninstalls Brewfile-declared packages — after showing the list and asking.
- **`defaults` writes are diffed first** (`defaults_write` reads before
  writing), so re-runs don't churn and Dock/Finder restart only on change.

## State layout

```
~/.local/state/mac-setup/
├── logs/       install-<run>.log, update-<run>.log
├── reports/    <run>.tsv, install-report.md, manual-actions.md, verification-report.md
├── backups/    <run>/<original files, in their $HOME-relative paths>
└── manifest/   symlinks.tsv   (what uninstall.sh will remove)
```

XDG state dir, outside the repo: reports survive re-clones, and the repo
never accumulates machine-specific litter.

## Testing & CI

macOS scripts are awkward to test in CI, so the pipeline covers what a Linux
runner *can* prove on every push:

- **ShellCheck** on every `.sh` (zero-warning policy; `.shellcheckrc`
  documents the one deliberate exception),
- **shfmt** formatting check (2-space indent),
- **`bash -n`** syntax pass,
- a **dry-run smoke test**: `MAC_SETUP_TEST=1 ./install.sh --dry-run` runs
  the full orchestration path with every mutation printed instead of
  executed — exercising flag parsing, module dispatch, logging, and report
  rendering end-to-end.

The remaining risk (does cask X actually exist?) is covered by the
fail-soft + manual-report design rather than by tests: a wrong cask name
degrades into a report entry, never a broken run.

## Extending

See [CONTRIBUTING.md](../CONTRIBUTING.md#adding-a-module) — new concerns get
a new module file plus a registry entry; the skeleton, helpers, and report
plumbing are already there.
