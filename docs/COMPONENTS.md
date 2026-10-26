# Component contract

The component consistency work uses the existing HTML controls and CSS layers;
it adds no UI framework. `style.css` owns geometry, spacing and semantic
materials. `liquid.css` consumes that geometry and owns decorative response.

Primary, secondary and tertiary actions differ in emphasis, with capsule action
surfaces and circular icon controls. Persistent selected/checked states belong
to profiles, categories, sources and checkboxes, not ordinary action buttons.
Catalogue and installation-confirmation checkboxes share the drawn mark while
retaining native checkbox semantics and keyboard focus.

Geometry uses named control, panel, window and mark radii, a 4/8/12/16/24/32/48
spacing vocabulary, 44px normal actions and 48px prominent actions. Dense source
links, compact navigation and nested corners retain their responsive/optical
exceptions in the component stylesheet. The motion layer must not override
component radii. Comparable review panels share their inset and heading origin.

Immediate feedback, elastic surface response and spatial transitions use the
shared quick/fast/slow duration and easing tokens. Ambient breathing and checkbox
stroke drawing retain their documented expressive timing.
Calm and system reduced motion override decoration. Disabled or busy actions
suppress press/hover deformation and pointer sheen. Starting an installation
sets `aria-busy`, disables duplicate activation, and clears busy state on success
or error; a failed start permits retry. Copy completion uses the existing Copied
feedback; normal actions do not acquire a persistent selected appearance.

## Internal control reference

Run from the repository root:

```bash
npm run test:browser -- --browser=chromium tests/browser/components.spec.mjs
```

The reference test clones the real current controls rather than maintaining a
second markup implementation. Screenshots under `test-results/` cover both
themes, Fluid/Calm, applicable states and long translated labels; compact width,
focus, geometry, native confirmation and a controlled busy/error transition are
checked. These are test artifacts, not another public product page or simulated
installation. The full browser suite also checks five locales, responsive
layouts, interrupted springs, reduced motion, accessibility and actual dry runs.

The completed implementation proposal was removed from
`outputs/consistency-review/REVIEW.md`; its original captures and Git history
remain historical evidence. Human VoiceOver, touch, visual/editorial review and
real installation acceptance remain in [ACCEPTANCE.md](ACCEPTANCE.md).

The Figma file still represents its saved desktop baseline. This runtime change
does not claim new Figma variants, editable phone layouts or automatic sync.

## Verification — 26 October 2026

The local Chromium suite passed all 26 cases, without retries, on the changed
source based on main `18abe0a`. Node 15/Python 21, catalogue and formatting checks
also passed. Source fingerprints are in `outputs/verification.json`.

Before splitting independent checks, the combined language journey exceeded its
60-second budget after successful interactions. Unchanged main also exhausted
the combined viewport/accessibility test's budget. An additional combined-language
repetition timed out at screenshot capture; another used almost the full budget.
Locale switching, keyboard/search/Safety, locale audits, viewport audits and
companion captures now have independent tests with the original deadlines and
assertions. The final locale-switching journey took 14.8 seconds, the keyboard/
search/Safety journey 12.0 seconds and the slowest viewport audit 28.7 seconds.
An earlier intermittent overflow observation was not reproduced in the final
suite; it is not assigned a speculative root cause.
The historical PR #8 timeout remains unresolved.

Local verification used Linux, Node 24.22.1, Python 3.12.14, Playwright 1.64.1 and
its pinned Chromium 156.0.8078.4 with an isolated browser dependency sysroot.
Docker, native macOS, Firefox and WebKit were unavailable locally for this pass;
hosted three-engine and native dry-run checks remain publication gates. A dry
run never establishes real Mac installation or human acceptance.
