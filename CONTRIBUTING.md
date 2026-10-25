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

For browser or catalogue changes, regenerate and verify the projection:

```bash
python3 -m web.catalog
npm ci --ignore-scripts             # development/QA only; no frontend runtime dependencies
npm test                          # selection rules, local API and isolated Bash dry-run
npm run check:catalog
npm run check:format
npx playwright install webkit
npm run test:browser               # public-to-local flow, responsive layout and axe
```

### Browser failure diagnosis

Browser tests keep retries disabled. Named motion steps and the JSON report in
`test-results/results.json` record phase durations. The HTML report in
`playwright-report/` also exposes fixture setup and teardown steps. CI runs
WebKit, Chromium and Firefox independently and uploads both report directories
on success and failure for seven days; failures also retain traces and
screenshots. Inspect the first failed step before blaming a later cleanup error.

Run the affected regression checks repeatedly on one source revision:

```bash
npx playwright test tests/browser/liquid.spec.mjs tests/browser/motion.spec.mjs tests/browser/visual.spec.mjs --workers=1 --retries=0 --repeat-each=5
```

`npm run test:browser` defaults to WebKit. Use `npm run test:browser:all` for all
three engines, or `npm run test:browser -- --browser=firefox` for one engine.
The CI matrix keeps artifacts separate by browser and does not cancel the
remaining engines when one fails.

Motion tests use Playwright's managed page/context fixtures. Functional CI does
not encode a demonstration video. To compare the same journey with recording
enabled, run `npm run test:motion:record`; its video is attached beneath the
test's unique `test-results/` directory. Tests do not overwrite the curated
`outputs/liquid-preview.webm` handoff recording. Keep the functional assertions
and the 60-second test budget unchanged unless measurements justify a scoped
change.

For local browser QA, prefer Docker with an image matching the pinned
`@playwright/test` version in `package.json`:

```bash
docker run --rm --init --ipc=host \
  --mount type=bind,src="$PWD",dst=/work \
  --mount type=volume,dst=/work/node_modules \
  --workdir /work \
  mcr.microsoft.com/playwright:v1.64.1-noble \
  bash -lc 'npm ci --ignore-scripts && npm run check:catalog && npm run check:format && npm test && npm run test:browser'
```

If Docker is unavailable, record that limitation and the native Linux runtime
versions. A Linux browser pass does not establish native macOS installation,
real sudo/App Store behaviour, VoiceOver acceptance or production verification.

Use `./web.sh --dry-run` for visual review. Keep installation tests in isolated
homes/state directories and never apply a real setup to the developer's Mac.
Browser plans are untrusted data: validate catalogue versions, prerequisites and
required items on the server. Keep the API loopback-only, authenticated and
restricted to its own origin. New official connections should be guided entries
until their account access can be reviewed explicitly by the person installing.

## Code style

For interface translations, edit `docs/assets/messages.mjs` with the canonical
English phrase and all four translations. Keep interpolation slots intact and
add `requestTranslation()` at new asynchronous render boundaries. Preserve app
names, command text and plan IDs. See the language contract in
[`docs/LIQUID_INTERFACE.md`](docs/LIQUID_INTERFACE.md).

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
