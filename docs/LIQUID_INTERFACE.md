# Liquid Acrylic interface

The browser keeps the profile → catalogue → review → local installation journey.
Its visual language follows the original mac-setup website: a dark background,
mint/sky/lilac accents, gradient headings, a floating translucent toolbar and
rounded Mac window chrome. Light mode remains available. All labels and controls
are live HTML; the generated aurora wallpaper contains no interface content.

## Material and interaction

- `assets/style.css` owns colour, typography, layout and responsive states.
- `assets/liquid.css` owns surface response, shared motion tokens, the native
  checkbox decoration, modal transitions and accessibility fallbacks.
- `assets/liquid.mjs` decorates existing controls. Shared SVG silhouettes follow
  the active profile and category with a leading body and a viscous trailing body.
  An alpha threshold joins nearby shapes. A pointer-following highlight and mild
  button surface deformation leave labels and hit targets intact.
- `assets/liquid-physics.mjs` integrates springs at 120 Hz, caps suspended frames,
  and uses reciprocal stretch axes to preserve projected area. Animation frames
  run only until the current surfaces settle; hidden documents stop the loop.
- The floating toolbar responds to scroll with a bounded offset of at most 4 px.
  The whole setup window uses the same spring and 4 px bound; its titlebar adds
  a subtle response of up to 1.8 px. Dialogs, log panes, the source list and horizontal category rail get
  bounded elastic shading when they scroll. Scroll stays native: no wheel, touch
  or keyboard scrolling is intercepted. At the existing 1050 px compact workspace
  breakpoint, the fixed summary moves into a sibling slot outside the transformed
  window. It stays anchored to the viewport and hides when the choices view closes.
  Returning to the desktop layout restores its original sidebar position and focus.
  Choosing a setup step returns smoothly to the heading.

The cursor sheen spreads across a wider ellipse at 45% opacity, with a 30%
titlebar sheen and a 40% window wash. This keeps the pointer response visible
without a bright spot competing with text.

**Fluid / Calm** in the toolbar is a local appearance preference. Calm disables
motion and uses opaque surfaces. System reduced-motion and reduced-transparency
requests always take precedence, including when Fluid is selected explicitly.
Forced-colour mode restores native checkboxes and system colours. Unsupported
backdrop filters fall back to opaque surfaces. Native radios, checkboxes, buttons
and dialogs retain keyboard operation and focus; decorative SVGs are hidden from
assistive technology. Escape dismisses dialogs immediately so the next keyboard
action is not lost during a closing animation. The close button and a press
on the backdrop animate dismissal and return focus to the opener. A drag that
starts inside the dialog does not dismiss it. The close control has fixed 44 px
square geometry, a circular material and a vector cross.

Catalogue rows and category buttons are retained when their contents do not
change. Checking an item does not replace its focused input or replay an entire
catalogue entrance. Filters reveal new content; selection counts animate only
when their actual value changes. Progress continues to reflect installer data.

## Shared controls and browsing

Text actions, navigation links, back/import/reset actions, source buttons and
icon buttons form a rounded glass body on hover or keyboard focus. Primary and
secondary actions share the same elastic surface response; the primary gradient
retains emphasis. Labels and hit boxes are not stretched. Heading gradient colours
move continuously only while the gradient text is hovered. Calm and system
reduced motion suppress these animations.

`assets/site.mjs` owns shared appearance and the visual three-step guide on the
setup and Safety pages. `assets/icons.mjs` owns decorative vector symbols.
`assets/source-picker.mjs` progressively enhances the native source select into
a glass listbox with arrow keys, Home/End, typeahead, Enter/Space, Escape, Tab,
outside dismissal and focus return. Elevated menus and dialogs use a denser
96% material token so underlying text cannot compete with their labels, with
opaque fallback in Calm. The menu opens upward when the viewport or floating
summary leaves insufficient space below. No breakpoint is tied to the annotated
932 px viewport. Existing 760 px navigation compaction is retained: Guide replaces
How it works, GitHub uses its mark, and the effects label is visually hidden while
its accessible name remains available. Navigation can wrap to accommodate the
language control and longer translations. Sidebar import/reset actions retain
12 px inline padding so their text aligns with the other sidebar controls.
Below 360 px the fixed summary places its action on a separate row so translated
labels have room. Its denser popover material keeps scrolling text from competing
with the summary's labels while retaining the glass rim.

## Languages

`assets/messages.mjs` owns English source phrases and Brazilian Portuguese,
French, German and Spanish (Spain) translations, including all 139 catalogue
descriptions. `assets/i18n.mjs` applies them at explicit render boundaries and
retains canonical English text for reversible language changes. Longer phrases
take precedence over broad interpolation templates; template slots are checked
in the Node suite. Translated descriptions also participate in search.

The shared language picker uses project-local round flags with full language
names and native-language option labels. Flags are decorative; accessible names
identify languages independently. It supports the source picker's keyboard and
focus contract. English (UK) is the default. A choice is saved only in this
browser, under `mac-setup.locale.v1`, and applies to setup and Safety.

App names, package tokens, plan IDs, commands, raw installer output, downloaded
reports and arbitrary vendor follow-up text retain their source wording. No
translation API is contacted. Translation files are editable source and have
automated coverage checks; native-language editorial review remains useful.

Each category ends with **Select all [category]**, aligned right. This includes
all items in that named category, even those hidden by search, source or the
six-item overview, and adds prerequisites through the same pure selection rules.
The title and announcement describe this scope. Already complete categories keep
the focused action in place with `aria-disabled`. Individual choices stay editable.

App and service entries use 77 local artwork assets covering 88 catalogue items,
including every current desktop app and all 22 App Store entries. Preferences and
other tools use category symbols. Failed artwork loads fall back to a category
symbol. `assets/app-icons.mjs` contains only the local mapping; sources, resource
names, versions where applicable and SHA-256 checksums are in
`assets/icons/manifest.json`. No remote icon service is called by the browser.
See [third-party notices](THIRD_PARTY.md).

## Safety and participation

`safety.html` explains browser storage, local confirmation and reports, temporary
loopback access, external provider requests and hosting access logs. It makes no
claim that third-party hosts or vendors collect nothing. It also describes the
repository’s MIT reuse terms and asks for a visible creator mention. The footer
and creator section link to both Pedro’s GitHub and LinkedIn profiles.

Footer actions open prefilled GitHub software suggestions or problem reports,
and Buy Me a Coffee. They do not submit an issue or a payment automatically. The
local server explicitly permits the Safety HTML page while retaining the existing
restriction on repository files and authenticated report APIs.

## Rendering scope

This is a functional CSS/SVG material, corresponding to Tier A of the supplied
Liquid Acrylic manual. CSS backdrop blur/saturation, coloured tint, a moving sheen
and a spring-driven silhouette produce the appearance. They do not perform
normal-based optical refraction of the composed page or solve Navier–Stokes.
The supplied lab's detachable controls, free-body bond graph and GPU optics are
research references rather than product requirements. Setup navigation stays
anchored and never requires dragging.

The Transitions.dev skill informed the motion scale, modal, checkbox stroke and
panel reveal patterns. Only the used modal snippet is incorporated directly;
native checkbox semantics are retained for the adapted check treatment. The
library, skill installer, agent service and generated CI integration are not
runtime dependencies. See [third-party notices](THIRD_PARTY.md).

## Verification

`npm test` covers catalogue selection, loopback API boundaries and deterministic
spring behaviour. `npm run test:browser` uses WebKit for the complete public-plan
handoff and an isolated actual Bash dry run, responsive and axe checks in both
themes, native keyboard selection, silhouette alignment and calm/reduced-motion
behaviour. Visual references and the comparison ledger live under `outputs/`.
The built-in browser is also used to inspect the actual local companion.

These checks do not install applications or apply macOS preferences on the
developer's Mac. Native touch hardware, VoiceOver and current Firefox/Chromium
rendering remain manual verification areas.
