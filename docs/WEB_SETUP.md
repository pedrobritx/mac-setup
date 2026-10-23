# Guided browser setup

The website plans a setup; a companion running on the Mac performs it. The same
static HTML, CSS and JavaScript power both surfaces. This preserves GitHub Pages
and the existing Bash installer, without adding a hosted execution service.

The original website's gradient palette and glass window treatment carry through
the catalogue, review, handoff and progress views. **Liquid / Calm** in the floating
toolbar controls decorative movement and transparency; the choice is remembered
locally and system accessibility preferences take precedence. See the
[interface implementation notes](LIQUID_INTERFACE.md).

## The journey

1. Start with **Essentials**, **Developer**, **Education**, **Productivity**,
   **Creative**, or **BRITX Choice**. Essentials is the initial default. BRITX
   Choice keeps the existing personal catalogue and adds the requested guided
   connections. It also selects paid apps, which are marked before confirmation.
2. Add or remove optional items. Prerequisites are visible in item details and
   selected together; removing one also removes the dependent setup step.
   Search and source/category filters cover the complete catalogue. The overview
   shows six entries per category before opening its full list.
3. Review and export `mac-setup-plan.json`. It contains a schema version, catalogue
   version, profile and selected IDs. It contains no commands, credentials or Git
   identity. Choices are remembered only in the current browser's local storage.
4. On the Mac, open the companion from an existing clone with `./web.sh`. On a
   fresh Mac the website's `bootstrap.sh --web` command installs Apple's Command
   Line Tools if needed, clones the project and launches the companion.
5. Import the plan, review again, optionally supply your own Git name/email, and
   explicitly confirm. Password prompts remain in Terminal. Leave it open.
6. Follow module progress, open official follow-up guides, and download the
   install/manual reports. Reopening the private link reconnects to the active
   run while the companion remains running. Closing the browser does not stop it.

```bash
./web.sh --dry-run                      # actual orchestration, commands only
./web.sh --plan ~/Downloads/mac-setup-plan.json
./web.sh --no-browser --port 3417        # print the private local link
```

The public launcher requires the browser changes to have been published to the
repository first. Local development and review work directly from this checkout.

## What is automated

The [generated inventory](CATALOG.md) is the full list. Homebrew formulae/casks,
App Store entries, configuration modules and preferences use the existing
idempotency/reporting helpers. The Finder, keyboard, trackpad, screenshot, Dock,
Safari, dialog and security choices already captured by the repository remain
individually selectable. Selecting macOS preferences also retains the existing
cleanup of legacy window/animation overrides, disclosed on the review screen.

- **App Store:** `mas install` uses the person's own Apple Account. Paid apps
  require prior purchase. Compatibility, regional availability, sign-in issues
  and missing entitlements become manual actions. No purchase is made.
- **Xcode:** Command Line Tools are required; full Xcode is a separate optional
  large download. Explicit plans defer full Xcode until Homebrew/mas are ready.
- **Terminal:** Starship, zoxide, fzf, history search, autosuggestions and syntax
  highlighting remain available. Oh My Zsh is optional and selected by BRITX
  Choice; it uses the official repository, reuses existing installs, enables Git
  helpers and interactive cd when fzf is present, and leaves Starship as the prompt.
  Zsh Navigation Tools is also selectable. It does not install a second copy
  of the Homebrew-managed plugins. Existing shell files are backed up.
  The framework-choice symlink is in the existing uninstall manifest. The Oh My
  Zsh checkout is retained on uninstall because it can contain personal plugins.
- **CLI bundles:** Docker Desktop supplies its Docker CLI/Compose/Buildx. GitHub,
  1Password, Claude Code, Codex, Supabase, Railway and Stripe have their own
  selectable CLI entries. Sign-in remains a follow-up.
- **Guided installers:** VMware Fusion uses Broadcom's portal. Gemini CLI and
  Vercel CLI point to their current official Node-based setup; Figma Code Connect
  is a project-specific guide. These are explicitly labelled **Guided**.
- **Browser apps:** Google Docs, Sheets and Slides produce links in the checklist,
  rather than installing invented desktop packages.
- **MCP:** Official GitHub, Figma, Docker, Notion, Vercel, Supabase, Railway,
  Stripe, Slack and Canva developer guides are included. Canva Dev MCP supplies
  developer context rather than access to personal designs. Selecting them writes follow-up guidance; it does
  not configure, authenticate, authorise or start a server. Other apps are not
  assigned speculative community servers. Choose scopes in the official flow;
  Supabase guidance starts with a read-only development project.

App Store sources win when supported. The current 1Password desktop app stays a
cask because its App Store listing is the legacy v7 build. DaisyDisk retains the
repository's existing cask exception for its fuller functionality. Exact store
IDs and package tokens were checked against Apple's lookup service and the
Homebrew API; see [CATALOG_SOURCES.md](CATALOG_SOURCES.md).

## Local execution boundary

- Bind only to `127.0.0.1`, with a random per-launch capability in the private URL
  fragment. The page moves it to session storage, never an exported plan or
  query string. All private APIs require its bearer token.
- Check the exact `Host` and same-origin `Origin`; reject cross-site requests.
  No CORS access is granted. Static serving is limited to the site and assets;
  repository files, reports and arbitrary paths are not publicly served.
- Validate schema, exact catalogue version, known IDs, unique selections, required
  tools and dependency closure before starting. Never source an imported file.
  The Bash picker independently rejects unknown selection keys.
- Accept no browser-supplied command, Brewfile, URL, module path, environment or
  dry-run override. Run one allowlisted installer at a time. The launch mode is
  authoritative and cannot be changed by the browser.
- Authenticate sudo in Terminal after confirmation. Keep passwords, OAuth tokens,
  agent settings and Apple purchases outside the browser form. A Git identity
  can be passed as plain environment data, and is never stored in the plan.
- Logs, backups and reports are per run under `~/.local/state/mac-setup/web/`.
  Dry-run sessions use a separate temporary state directory. Files use a private
  umask. There is no telemetry or remote installation state.

Explicit plans skip global upgrades and unselected macOS/security modules, and
verify the actual selection. They may install the normal dependencies of selected
Homebrew packages. An individual failed module is reported while later modules
continue; a nonzero final exit is shown as needing attention. Previews are always
labelled dry runs, including in downloadable reports.

The companion is intentionally session-scoped. Keep Terminal open until the run
finishes. Control-C interrupts it; it is not an always-on daemon. Reports survive
under the state directory, but a new companion process requires another review
before a new installation. There is no automatic restart or resume after a reboot.

## Development and evidence

`python3 -m web.catalog` regenerates the browser catalogue and human-readable
inventory from the real picker. Presentation/profile metadata lives in
`config/web-catalog.json`; executable packages stay in the Brewfile. The browser
has no runtime npm dependencies; npm packages are only for formatting and QA.

Run `npm test`, `npm run check:catalog`, `npm run check:format`, the existing
ShellCheck/shfmt/Bash checks, and `npm run test:browser`. Browser tests use WebKit
with desktop/mobile viewports, both themes, and axe; the installation test runs
the real Bash orchestrator in dry-run mode with an isolated home/state directory.

Those checks prove planning, the public-to-local handoff, validation, reporting
and the preview path. They do not prove a fresh Mac install, sudo prompts,
App Store ownership, vendor authentication, native screen-reader usability, or
MCP access. Test those separately on a disposable Mac before treating the new
browser path as release-validated. This repository does not install anything on
the developer's Mac during QA.
