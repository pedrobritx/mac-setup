# Acceptance evidence

Use the tests below to distinguish deployed browser behaviour, native dry-run
compatibility and actual installation/human acceptance. A pass in one category
does not fill in the others.

## Automated browser acceptance

```bash
# Rehearse against local static files and an isolated dry-run companion.
npm run test:production:local -- --browser=all

# Verify the live public site against this checkout, with the same isolated companion.
npm run test:production -- --browser=all
```

Use a checkout matching the deployed revision for live checks. The suite checks
the home/Safety pages, catalogue and runtime assets byte-for-byte; public source
filtering, plan export/import and Safety navigation; and a public export imported
into an isolated loopback companion. Starting its dry run requires confirmation,
and the downloaded report must explicitly identify dry-run mode.

The suite starts its own test companion and refuses to reuse an existing server
on port 3420. It never connects to a person's running companion. Its only public
target is `https://mac-setup.britx.me/`; local rehearsal uses port 3419.
HTTPS verification stays enabled. An optional `MAC_SETUP_TEST_PROXY` is for
development environments with a trusted network proxy; it does not disable TLS
checks or accept credentials in the proxy URL.

Prefer the Docker recipe in [CONTRIBUTING.md](../CONTRIBUTING.md), replacing its
last command with `npm run test:production:local -- --browser=all` as needed.
Reports are written under `test-results/production/` and
`playwright-report/production/`, separately from the existing browser suite.

The normal CI matrix runs the local rehearsal on all three engines. The
`Deployed site acceptance` workflow runs after successful same-repository
main-branch CI, and can also be dispatched manually. Before checking the live
site, it requires a successful GitHub-managed Pages deployment of that exact
revision, with a three-minute bounded wait. A failed or missing deployment fails
the gate; an older deployment cannot satisfy it. The checked-out revision and
browser report metadata use the triggering CI's source SHA.

The first PR #10 merge (`dfbed94`) passed main CI and Pages, but the original
`workflow_run` subscription to the GitHub-managed dynamic Pages workflow did
not start any acceptance run. The follow-up uses the repository's normal CI
workflow as its entry point and checks Pages explicitly. Its actual hosted
trigger remains unverified until the follow-up merges and runs; a configured
trigger alone is not evidence of execution.

## Native macOS dry-run compatibility

```bash
python3 tests/acceptance/native_macos.py
```

The native CI job and this command record the actual macOS version, architecture,
Python/system Bash versions, source commit, worktree state, Bash syntax checks
and four installer smoke commands. The smoke commands use an isolated temporary
home/state directory and explicitly enforce dry-run mode. Evidence is saved to
`test-results/native-macos/summary.json`, including a failure/refusal record.
On another OS the collector exits with code 2, records `not_run`, and executes
no installer checks.

Each native smoke command has a five-minute budget. The collector stops its
entire subprocess group before removing the temporary home, including on timeout.
The first hosted probe completed 31 syntax checks and three smoke commands,
then exceeded the original 60-second budget during the BRITX dry run. That is
collector failure evidence, not a failed real installation.

This evidence covers native command compatibility. It does not demonstrate a
fresh real installation, sudo/App Store approval or human accessibility. Run
installation acceptance on a disposable Mac or suitable isolated macOS VM.

## Human and real-installation checklist

Copy this table into a dated record for the exact source revision under review.
Leave every row unverified until the person performing it records what happened.
Keep credentials, recovery keys and private logs out of shared evidence.

Environment/revision: ____________________

Reviewer/date: ____________________

| Case | Required observation | Status | Observed result / evidence |
| --- | --- | --- | --- |
| Fresh installation | Review a minimal plan, apply it on the disposable Mac, and compare installed results with the report. | Not run | |
| Idempotency | Repeat the same plan; satisfied actions skip and personal files remain intact. | Not run | |
| Sudo approval | Approve through Terminal and observe the selected operations only. | Not run | |
| Sudo cancellation | Cancel approval; verify the report and the actual unchanged system state. | Not run | |
| App Store signed out | Observe guidance or a truthful needs-attention outcome; no false success. | Not run | |
| Licensed/paid app | Use only an already-authorized entitlement; verify the outcome without making a purchase for this test. | Not run | |
| Vendor/MCP setup | Complete the requested connection with the account holder; record the outcome without tokens. | Not run | |
| VoiceOver | Navigate profiles, sources, details, review, handoff and progress; verify names, announcements and focus. | Not run | |
| Calm/reduced motion | Verify the native system preference and calm mode remain usable and readable. | Not run | |
| Safari / visual review | Inspect desktop/mobile layouts, contrast, floating summary and dialogs on actual supported browsers. | Not run | |
| Physical touch | Use real touch hardware for selections, scrolling and dismissal. | Not run | |
| Production performance | Measure fluid/calm frame behaviour on target hardware, recording conditions and measurements. | Not run | |
| Language review | A qualified reviewer checks meaning, terminology and truncation in each locale. | Not run | |
| Real production handoff | Export from the live site and complete the reviewed installation on the disposable Mac. | Not run | |

## Evidence recorded in this follow-up

- PR #9 merged at `508da303e135195e068d01900994f4336f2d0f9e`; its merged-main
  CI and Pages deployment passed.
- Local rehearsal of this new suite passed all nine cases across WebKit,
  Chromium and Firefox.
- The import check clears the saved plan and verifies the exported choice is
  absent before import. Disabling the import handler in a local negative control
  fails the post-import checkbox assertion. Native collector success and timeout
  controls also verified descendant cleanup before removing its temporary home.
- The live Chromium suite passed all three cases, including the public export
  and isolated companion dry run. The local managed-network CA was trusted in
  a temporary browser profile; TLS validation was not disabled.
- The native collector's Linux refusal was executed and checked: exit 2,
  `not_run`, no installer checks. Actual Darwin results belong to the native
  CI artifact for the tested commit; they cannot be inferred from Linux.
- The historical motion timeout remains unreproduced. New acceptance coverage
  does not retrospectively establish its internal cause.
