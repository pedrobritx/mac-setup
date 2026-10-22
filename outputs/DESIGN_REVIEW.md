# Liquid Acrylic design and verification

Updated 22 October 2026. This supersedes the previous light/burgundy design review.
The work is local and uncommitted. No GitHub publication, deployment, real Mac
installation, purchase or account/MCP authorisation was performed.

## References and actual renders

- Original live site, inspected in the built-in browser: `design/liquid/original-site.png`.
- Full setup concept: `design/liquid/setup-concept.png` (1536 × 1024).
- Full progress concept: `design/liquid/progress-concept.png` (1536 × 1024).
- Prompt/source provenance: `design/liquid/PROMPTS.md`, `../docs/THIRD_PARTY.md`.
- Actual default desktop: `preview-desktop.png`; personal profile: `preview-britx.png`.
- Actual light theme: `preview-light.png`; mobile: `preview-mobile.png` and
  `preview-mobile-catalogue.png` (390 × 844).
- Actual review: `preview-review.png`; real isolated dry-run completion:
  `preview-progress.png` (1536 × 1024). `preview-progress-initial.png` is an actual
  earlier pending state, with disabled reports and zero processed steps.
- Native built-in browser view: `preview-in-app.png` (923 × 932).
- Native frame during a liquid bridge: `preview-liquid-motion.png`.
- Recorded WebKit interaction, with no simulated installation: `liquid-preview.webm`.

The built-in browser was used first to inspect the original and current UI, then
again for profile changes, Fluid/Calm, the glass dialog, Escape dismissal and
local review. WebKit supplies additional deterministic 1536 × 1024 and mobile
captures and full workflow verification. Playwright Chromium was not used as a
fallback. Static screenshots fast-forward finite decorative animations; the
video and native motion frame retain the actual movement.

## Visual comparison ledger

The concepts and final actual renders were inspected directly with `view_image`.
The implementation follows the user's original-site direction, with these
explicit choices where the generated concepts differ from the product:

| Area | Reference → implementation and verification |
| --- | --- |
| Palette | Original charcoal, mint, sky and lilac restored; burgundy removed. Both themes use the same hierarchy, with darker gradient text in light mode. |
| Background | Separate generated aurora asset gives complete, flowing ribbons. It contains no interface pixels and is bundled locally. Calm removes it. |
| Window geometry | Both concepts and render use one large rounded Mac window, decorative traffic lights, a thin titlebar and the three setup steps. Main window begins around y245 at native desktop size, close to the reference's y240. |
| Navigation | A floating glass capsule contains the brand, How it works, Safety, GitHub, Fluid/Calm, theme and round language controls; its native hit targets remain functional during bounded scroll movement. |
| Typography | System typography keeps the original familiar character. Main title is 60px desktop, 48px tablet and 33–44px phone. Names, descriptions, counts and source links remain live text with distinct weights/sizes. Selected-profile descriptions were brightened for contrast over the coloured material. |
| Catalogue layout | The existing two-column desktop checklist is intentionally retained because Pedro explicitly liked the new browsing organisation. The generated concept's single list was not substituted. Phone uses a single column and a horizontal category rail. |
| Icons | Genuine macOS app artwork, Apple artwork and brand marks replace monograms: 77 bundled files cover 88 catalogue items, including all desktop app entries and 22 App Store entries. Other tools/preferences use consistent category symbols. All runtime icon requests stay on the site origin; source and checksum provenance is retained. BRITX Choice keeps its recommendation star. |
| Profile and category state | Native selection drives a shared SVG body plus a trailing body. Their silhouettes stretch and form a fluid bridge while labels stay crisp. Resize snaps to the new layout, and rapid retargeting settles on the actual final choice. |
| Summary | A side panel on desktop becomes a compact floating review bar on tablet/phone. The primary action is in the initial viewport at all checked sizes. Removable chips and keyboard focus remain usable. |
| Progress | Timeline, reports and follow-ups use the same window/material family. Actual module count, follow-up ordering and “Previewed” labels come from the real run; invented concept counts and “Completed” claims are not copied. |
| Readability and motion | The render uses restrained rims and glow relative to the neon concept. CSS/SVG creates a glass-like material, not accurate scene refraction. OS preferences and explicit Calm keep controls static and opaque. |

Above-the-fold copy was compared with the allowed existing UI and concept brief:
brand, title, subtitle, three setup steps, six profiles, Browse, search, filters,
Your setup and Review setup remain. Functional chrome also includes Safety, category selection and Fluid/Calm. Phone navigation uses Guide and a GitHub mark at the existing compact breakpoint. The existing “Clear optional” and exact catalogue
copy take precedence over rewritten/generated concept labels. There are no new
marketing metrics, unsupported account claims or decorative hero badges.

Material issues found and fixed during visual/interaction QA: global SVG icon
sizing had reduced the liquid layer to a tiny mark; the layer now uses measured
pixel dimensions. Native keyboard focus survives category changes, checkbox
updates and chip removal. Escape dismisses immediately. Completion checks animate
only when their module first finishes. Previous-run presentation is cleared
before a new request yields; completion captures wait for the new visible run and
an enabled report, avoiding a stale hidden completion or an entrance-frame image.

## Executed verification

- 15 Node tests: selection rules, translation coverage and interpolation precedence,
  frame-rate independence, suspension bounds, spring convergence and area-preserving stretch.
- 17 Python tests: real isolated Bash dry runs, plan/API validation and loopback
  transport/security boundaries.
- 14 WebKit tests: native keyboard input and focus, rapid retargeting, motion video,
  Calm persistence, system reduced motion, public export/local import/confirmation,
  real dry-run reports, paid/MCP guidance, responsive layout, axe and visual states,
  five-language switching/persistence/search, and actual whole-window motion with a fixed summary.
- Automated WCAG 2/2.1 A/AA: zero axe violations in both themes at 1536 × 1024,
  923 × 932 and 390 × 844, including review; no horizontal page overflow.
- Catalogue drift, Prettier, JavaScript syntax and `git diff --check` pass.
- Native Node 24.21.0 / Python 3.9.6. Docker daemon was unavailable; native macOS
  WebKit and isolated installer tests are the applicable checks for this slice.

VoiceOver, physical touch hardware, production FPS profiling, current
Firefox/Chromium rendering and installation on a fresh Mac remain manual checks.
Vendor sign-ins, paid App Store entitlements and MCP permissions are not activated
by these tests. Remote CI and production publication remain outside this local
handoff. `verification.json` records the final evidence boundary.

## Browser annotation pass — 22 October 2026

All 20 requested comments are addressed in source, rather than temporary preview
attributes. The 932 × 932 annotation viewport informed inspection; the existing
760/360 px compact navigation patterns and available-space measurements own the
responsive decisions.

| Comments | Implementation and evidence |
| --- | --- |
| 1 | Fluid label and accessible action strings are set consistently in HTML and shared appearance code. Existing internal storage values are retained for compatibility. |
| 2, 10, 11, 18, 19 | Navigation, back/import/reset/text/icon controls form the same rounded hover/focus body. Primary and secondary surfaces share spring timing and press response; the primary keeps its gradient. The refreshed motion recording includes the guide, source list, scrolling, secondary action and back action. |
| 3 | Source picker is a real keyboard listbox over the existing native-select values. It supports arrow keys, Home/End, typeahead, Enter/Space, Tab, Escape and outside dismissal. It flips above the fixed summary and repositions while the page settles. Source selection, reopening, focus and filtering are tested. |
| 4 | Each category has a bottom-right Select all action. It selects the entire category, including filtered/overview-hidden items, and closes dependencies without changing unrelated choices. Browser verification includes a Python-only search, selection of hidden Development items, focus retention and persistence. |
| 5 | Creator credits link to GitHub and LinkedIn. The GitHub profile's public social link verified the LinkedIn handle. The explicit future preference was saved as a separate memory note, without editing the memory registry. |
| 6, 7, 12 | The follow-up pass now moves the whole window and navigation by up to 4 px using the same spring, with a 1.8 px titlebar response. Nested scroll surfaces receive bounded elastic shading. Scrolling remains native. At compact widths the fixed summary moves outside the transformed window so its ancestors remain untransformed. |
| 8 | A dedicated Safety page explains the actual browser/local/provider boundaries, host access logs, local confirmation and reports, MIT reuse and appreciated attribution. The exact public HTML route is tested without exposing repository files or private reports. |
| 9 | All app entries have genuine app artwork or brand marks, including all 22 App Store entries. 77 local files cover 88 items. Source manifests and checksum validation are retained; a failed image falls back to a category symbol. |
| 13 | Gradient colours animate continuously only while that text is hovered; Calm and reduced motion suppress it. |
| 14, 20 | Footer offers Buy Me a Coffee plus prefilled software suggestions and problem reports. URLs contain helpful prompts; no issue or payment is submitted automatically. |
| 15–17 | A fixed 44 × 44 circular close control uses a vector cross. The guide is a semantic three-step flow, matching the Safety data-flow cards. Backdrop click and close button use the same exit; focus explicitly returns to the opener in WebKit. An inside-to-outside drag does not close it. Escape stays immediate. |

New actual renders: `preview-source-picker.png`, `preview-category-selection.png`,
`preview-how-it-works.png`, `preview-safety.png`, `preview-safety-mobile.png`,
`preview-guide-in-app.png`, `preview-safety-in-app.png`, and
`preview-interactions-in-app.png`. The native browser additionally verified pointer
and keyboard source selection, Safety navigation and backdrop dismissal. Existing
setup/review/progress renders and `liquid-preview.webm` have been refreshed.

QA caught and corrected source-menu overlap with the floating summary, premature
menu dismissal during search-driven scroll settling, WebKit modal focus return,
phone visible/accessible label mismatch and inline-link distinguishability.
Elevated menu/dialog materials were made denser after image inspection to prevent
underlying text competing with foreground content when blur composition differs.
Safety and setup receive automated axe checks in light and dark themes; Safety
also covers 320 px, source-menu and visual-guide states. No remote asset request
is made during the checked navigation flow.

## Language and motion follow-up — 22 October 2026

The three follow-up annotations and cursor-light request are implemented and
verified locally. The earlier usage-limit handoff is resolved.

- The header has round project-local flags and complete language names for English
  (UK), Brazilian Portuguese, French, German and Spanish (Spain). The 471 source
  phrases include every catalogue description. Browser storage remembers the
  language across setup and Safety. App names, commands, plan IDs, raw logs,
  reports and arbitrary vendor follow-up wording remain intact.
- Language selection supports pointer and keyboard interaction. Tests verify
  unchanged saved plans, switching back to canonical English, fresh render labels,
  translated search, a fully translated category tooltip, and zero axe violations
  on the setup in all five languages. Setup widths 932, 390 and 320 px are checked
  for horizontal overflow after the measured surfaces settle.
- Sidebar import/reset actions use 12 px inline padding. The native browser
  confirms alignment in `preview-sidebar-spacing-in-app.png`.
- A 30-frame WebKit check observes actual window transforms after native wheel
  input: window/nav motion matches within 0.05 px and remains bounded to 4 px.
  The compact summary's viewport position stays constant. Calm removes the
  transform; resizing to desktop restores the sticky sidebar.
- Cursor sheen is broader and dimmer: shared highlights at 45%, titlebar at 30%,
  window at 40%. The 1050 px existing workspace breakpoint owns summary placement.
  At the existing 360 px breakpoint the summary action gets its own row for long
  translations. The fixed summary uses the denser popover material for readability.

Actual renders inspected: `preview-language-picker.png`, `preview-portuguese.png`,
`preview-portuguese-mobile.png`, `preview-portuguese-safety-mobile.png`,
`preview-languages-in-app.png`, and `preview-portuguese-progress-in-app.png`.
The native browser also confirms translated completed dry-run progress and the
corrected Verification stage. Translation source and template coverage are tested;
native-language editorial review has not been performed.

Final checks: 15 Node + 17 Python + 14 WebKit tests passed (46 total), catalogue
projection matches the installer, Prettier passes, all 12 browser modules pass
syntax checks, and `git diff --check` passes. No new runtime dependency or remote
translation request was introduced. The changes remain uncommitted and unpublished.
