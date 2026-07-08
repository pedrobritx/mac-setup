# Contributing

Thanks for helping improve mac-setup! This project is held to
production-infrastructure standards even though it configures a laptop.

## Ground rules

1. **Idempotency is non-negotiable.** Every action must check state first
   (use the predicates in `lib/checks.sh`) and be a no-op when satisfied.
2. **All state changes go through `run`** (`lib/run.sh`) so `--dry-run`
   keeps working. If you call a command directly, dry-run users will hate you.
3. **Report every outcome.** Use `report_ok` / `report_skip` / `report_fail`
   / `report_manual` so the install report stays truthful.
4. **Official sources only.** Homebrew → `mas` → official CLI installer →
   official DMG → manual instructions. No unofficial mirrors, ever.
5. **Never destroy user data.** Back up with `backup_file` before replacing
   anything; ask with `confirm` before anything destructive.

## Development workflow

```bash
git clone https://github.com/pedrobritx/mac-setup.git
cd mac-setup
# hack hack hack
./install.sh --only <your-module> --dry-run --verbose   # preview
shellcheck $(git ls-files '*.sh')                       # lint
shfmt -d -i 2 -ci $(git ls-files '*.sh')                # format check
```

CI runs ShellCheck, shfmt, `bash -n`, and a Linux dry-run smoke test on every
push — PRs must be green.

## Code style

- Bash with `set -euo pipefail`; 2-space indent (`shfmt -i 2 -ci`).
- Every function gets a comment block describing what it does (and why, when
  non-obvious).
- Constants at the top, `readonly` where possible.
- Prefer `lib/` helpers over ad-hoc logic; if you need a helper twice, it
  belongs in `lib/`.
- Keep modules single-purpose: a new concern gets a new file in `scripts/`
  plus a registry entry in `install.sh` (`MODULES` + `module_description`).

## Adding a module

1. Create `scripts/<name>.sh` from an existing module's skeleton (header
   comment, `source lib/common.sh`, documented functions, `main`).
2. Register it in `install.sh` — add to `MODULES` in dependency order and add
   a line to `module_description`.
3. Add verification probes to `scripts/verification.sh`.
4. Document it: README feature list + `docs/ARCHITECTURE.md`.
5. Update `CHANGELOG.md` under **Unreleased**.

## Commit messages

Conventional-ish and descriptive: `feat(terminal): add tmux config`,
`fix(brew): retry bundle on network failure`. Explain *why* in the body when
the diff doesn't make it obvious.
