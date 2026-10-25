# Browser CI reliability follow-up

Local verification: 24 October 2026 (Brasília).
Baseline: `e8eb8a053b2ec41a028a5289229aecdde84ca034`, the merge of PR #8.

## Problems and changes

The last PR #8 workflow exceeded the motion test's 60-second budget and reported
an error at a manually owned `context.close()`. Its trace was not uploaded, so
the underlying cause cannot be reconstructed from the retained logs. A cleanup
exception could also replace an earlier assertion error in the test's `finally`
block.

The follow-up uses Playwright's managed page/context fixtures, names the motion
journey's phases and keeps JSON and HTML reports. The HTML report includes
fixture setup and teardown timing. Each CI browser job uploads its reports,
failure traces and screenshots for seven days, even when tests fail. Retries
remain disabled and the functional test budget remains 60 seconds.

Video recording is now an explicit QA mode through `npm run test:motion:record`.
It exercises the same assertions and saves videos as unique test attachments.
The functional CI path does not depend on encoding a demonstration video or
overwrite the curated handoff recording in `outputs/`.

Browser coverage now includes independent WebKit, Chromium and Firefox CI jobs.
One engine's failure does not cancel the other engines' evidence collection.
Local multi-engine checks are available through `npm run test:browser:all`.

That broader validation exposed a concrete Firefox test defect: a 44 px close
button was measured as `43.99998474121094` px after a transform. The assertion
now tolerates less than 0.005 px of rounding while keeping the 44 px target.
No application-size change was needed.

The spring-settling guard and delayed-frame regression introduced in
`5b9bc761d6e82aed23013805509762c3d2e682d3` remain in place. The verification
record now correctly states that the spring fix merged through PR #8.

## Local evidence

| Check | Result |
| --- | --- |
| Original recorded motion test, unchanged from main | 3/3 passed; historical timeout not reproduced |
| Focused liquid/motion/visual tests, five repetitions | 30/30 passed, retries disabled |
| Full WebKit suite | 15/15 passed |
| Full Chromium suite | 15/15 passed |
| Full Firefox suite after the rounding correction | 15/15 passed |
| Firefox guide rounding regression | 3/3 consecutive passes after failing before the correction |
| Final guide check through the multi-engine command | 3/3 passed across WebKit, Chromium and Firefox |
| Managed recording mode | 3/3 passed; three distinct report attachments have valid WebM headers |
| Controlled body failure plus cleanup failure | Both original errors retained, with screenshot, valid trace and named phase |
| HTML report | Embedded report archive valid; fixture setup/teardown steps present |
| Node and Python | 15 Node and 17 Python tests passed |
| Shell | Bash syntax for 31 scripts, ShellCheck 0.10.0 and shfmt 3.10.0 passed |
| Installer smoke | Help, list, standard dry run and BRITX dry run passed in an isolated home |
| Catalogue, formatting and whitespace | Passed |

The original recorded journey took about 39 seconds in three runs. The managed
functional journey took 27–35 seconds in five runs. This comparison changes
context ownership and recording together; it does not prove that recording
caused the historical timeout. Keep that cause unresolved unless a future
failure or controlled reproduction supplies stronger evidence.

## Environment and limits

The local runner used Ubuntu 24.04, Node 24.22.1, Python 3.12.14 and the existing
Playwright 1.64.1 lockfile. Browser versions were WebKit 27.2, Chromium
156.0.8078.4 and Firefox 157.0.

Docker was unavailable here. Browser libraries were extracted into an isolated
temporary sysroot rather than installed system-wide. Playwright's host-library
cache validation was bypassed for that sysroot. Firefox initially crashed before
loading the app because the runner denied `uid_map`; local-only content/GMP
sandbox environment adjustments allowed its tests to run. These runner-specific
adjustments are not added to the GitHub workflow. Hosted CI remains a separate
verification gate.

The live home page, Safety page, catalogue, `liquid.mjs` and `app.mjs` all returned
HTTP 200 and matched the merged main revision byte-for-byte. This establishes
asset availability and version consistency, not interactive production acceptance.

Still pending: installation on an isolated Mac; real sudo and App Store flows;
licences and vendor/MCP account authentication; human VoiceOver acceptance;
physical touch hardware; human cross-browser visual review; production FPS;
native-language editorial review; and interactive production/local-companion
acceptance. Existing dry-run specimens do not establish real installation.

## Evidence links

- [Historical failed PR workflow](https://github.com/pedrobritx/mac-setup/actions/runs/39888755209)
- [Successful merged-main workflow](https://github.com/pedrobritx/mac-setup/actions/runs/39900406869)
- [Original spring fix](https://github.com/pedrobritx/mac-setup/commit/5b9bc761d6e82aed23013805509762c3d2e682d3)
- [Contributor commands and Docker recipe](../CONTRIBUTING.md#browser-failure-diagnosis)
- [Machine-readable verification record](../outputs/verification.json)
