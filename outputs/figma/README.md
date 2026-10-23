# mac-setup · Liquid Acrylic design handoff

[Open the editable Figma file](https://www.figma.com/design/OU3tjfPMFYA2Sz3QtpVWqu?node-id=16-2)
in the **Projects** team. This file records the approved implementation from
[mac-setup](https://github.com/pedrobritx/mac-setup), initially published in
[PR #7](https://github.com/pedrobritx/mac-setup/pull/7). Its source baseline includes
[the bounded spring-settling fix](https://github.com/pedrobritx/mac-setup/commit/5b9bc761d6e82aed23013805509762c3d2e682d3).

## File structure

| Page | Contents |
| --- | --- |
| 00 · Start here | Source, implementation and variable links; scope and font notes |
| 01 · Foundations | Dark and Light colour specimens, geometry, typography and motion contract |
| 02 · Components | Eight reusable families with ten current-state variants |
| 03 · Screens | Choose & customise, review, guided handoff, progress specimen, Safety |

Screens contain **482 editable text layers** and native frames, vectors and
individual image fills for artwork. Nine controls on the Choose screen are
instances of the reusable components. The remaining captured controls are
editable native layers. The interface is not a flattened screenshot.

The components cover primary, secondary, tertiary and icon actions, profile
cards, categories, a catalogue row and an unchecked checkbox. Captured profile
and category components retain their own resting/selected styling; the moving
selection rail belongs to the surrounding browser group. The complete proposed
hover/press/focus state matrix in the [consistency review](../consistency-review/REVIEW.md)
is future guidance, rather than a claim about completed variants.

## Variables and source mapping

The file contains **119 variables** in four local collections:

| Collection | Variables | Mapping |
| --- | ---: | --- |
| Primitives | 44 | Concrete Dark/Light colour values; hidden implementation primitives |
| Appearance | 27 | 22 semantic colours with aliases in Dark/Light modes, radius, ambient opacity and three CSS strings |
| Geometry | 33 | Existing CSS spacing and radius literals with appropriate numeric scopes |
| Motion | 15 | Source duration, easing, scale and checkbox values preserved as strings |

There are also five local SF Pro text styles. Semantic colour, corner-radius
and spacing bindings are applied to foundations, component masters and screen
layers. The read-back inspection found 1,089 bound nodes on the Screens page.
Complex gradients, shadows, artwork and some captured literals retain their
native values; changing Appearance mode is not a complete re-render of every
captured screen.

- [CSS appearance source](../../docs/assets/style.css)
- [CSS material and motion source](../../docs/assets/liquid.css)
- [Runtime motion implementation](../../docs/assets/liquid.mjs)
- [Source-exported CSS tokens](../../docs/design-tokens.json)
- [Figma variable values, aliases, modes, scopes, code syntax and node ledger](variables-export.json)

The links run both ways: this repository links to Figma; the Figma cover and
component descriptions link to GitHub. This is a documented source mapping and
saved baseline, without automatic two-way synchronisation or Code Connect.
Code remains authoritative for installation, accessibility and interaction
behaviour. To refresh the design, compare changes against these source files
and update the existing Figma nodes and bindings in place.

## Verification and limits

The cover, foundations, component board and all five desktop layouts were
rendered and inspected in Figma. Conversion corrections restored unchecked
checkboxes, the first catalogue row's grid cell, primary icon spacing, heading
gaps, expanding documentation text, review group labels and content height, and
the completed progress fill. Temporary duplicate captures were removed after
the editable layouts were checked. Preview PNGs are evidence of the Figma
canvas, not replacements for its editable layers.

SF Pro is available in Figma. Unavailable Menlo ranges use **Cousine Regular**
in the design file; runtime font choices are unchanged. Browser spring physics,
pointer light and elastic surfaces remain implemented in code. Motion string
variables document that contract rather than simulate it in Figma.

The progress layout is a **design specimen with deterministic dry-run fixture
data**, not evidence that applications were installed. No real Mac installation
was performed. The saved layouts are 1,280px desktop references. A phone capture
could not be verified with the available browser controls and is not included
as an editable phone layout. The implementation's responsive WebKit tests and
[phone screenshot](../preview-mobile-catalogue.png) remain separate evidence.

Local validation for the runtime baseline: **15 Node, 17 Python and 15 WebKit
tests passed**; format, catalogue, shell and whitespace checks passed. The
[GitHub CI run for the spring fix](https://github.com/pedrobritx/mac-setup/actions/runs/39886266290)
also passed. Publishing this handoff does not itself merge a follow-up PR or
prove production deployment, paid-app entitlement, vendor authentication or
human screen-reader acceptance.

## Build provenance

`create-foundations.js`, `build-foundation-page.js`, `build-components.js` and
`build-screens.js` record the initial Figma construction steps. They are
**historical, non-idempotent Plugin API snippets**, not a package, browser
runtime or sync command. Their capture source IDs refer to temporary nodes
that were removed during canvas cleanup. Later visual corrections are recorded
above; do not replay the snippets against the completed file. The state ledgers
preserve construction IDs, and `variables-export.json` records the final saved
variables and screen structure.

Created by Pedro Brito · BRITX:
[GitHub](https://github.com/pedrobritx) ·
[LinkedIn](https://www.linkedin.com/in/pedrobritx/).
