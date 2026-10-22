# Component consistency review

22 October 2026. Recommendations only; application code and saved installation
choices were not edited. Fresh captures from the current in-app browser ground
this bounded desktop review. The choices screen was restored afterward.

## Captured steps

### 1. Choices and catalogue — coherent foundation

The window, profile cards, sidebar and primary action have a recognisable family.
Selection is legible and the main action has clear emphasis. The small source
actions and independent spacing values are the main candidates for consolidation.

![Choices and catalogue](01-choices.png)

### 2. Three-step guide — coherent geometry and hierarchy

The circular close target, rounded dialog, connected steps and dense foreground
material work well together. Keep this as the reference for modal geometry,
content padding, close controls and focus restoration.

![Three-step guide](02-guide.png)

### 3. Review — clearest component inconsistency

The gradient primary action and outlined export action establish hierarchy.
The confirmation checkbox uses a native square appearance, whereas catalogue
checkboxes have a rounded glass surface and drawn checkmark. The left section
heading is outside its container while the right heading is inside its card;
their different insets make the two columns feel less deliberately aligned.

![Review](03-review.png)

## Recommended component contract

Treat emphasis, shape, interaction and outcome as separate decisions.

| Family | Resting appearance | Hover and focus | Press and release |
| --- | --- | --- | --- |
| Primary action | Mint/sky/lilac fill, strongest contrast | Slightly brighter rim and soft surface response | Fast deformation, restrained spring return |
| Secondary action | Quiet glass with a visible outline | Tint and rim strengthen using the same timing family | Same response, lower amplitude |
| Tertiary action | Readable text/icon with a transparent surface | Rounded body forms; keyboard focus also has an explicit ring | Brief surface compression and return |

Icon-only is a geometry variant of an emphasis level. Accent is a colour modifier.
Neither needs its own unrelated interaction system. Navigation, filters and
selection cards have persistent states distinct from momentary action buttons.

Every applicable family needs resting, hover, focus-visible, pressed, disabled,
busy and completion rules. Persistent selected/checked/expanded states apply only
to controls with those meanings. A normal action does not remain visually pressed
after a click. Copy may briefly show a checkmark and “Copied”; a filter retains its
selected fill until it is turned off. Busy controls retain their width, explain
the operation and prevent duplicate activation. Disabled controls suppress
decorative spring/glow while remaining readable.

## Shape and spacing proposals

These are proposed starting values, not measurements of every current component.

- Use a small radius vocabulary: 6–8 px for small marks, 16 px for cards/fields,
  24 px for panels/dialogs, 28 px for the main window, a true capsule for action
  buttons and a true circle for icon controls. Nested corners should generally
  reduce with their inset; permit documented optical corrections.
- Use 44 px normal action targets, 48 px prominent actions and a compact visual
  variant for dense catalogue controls with an adequate hit area. Establish shared
  icon sizes, label metrics and horizontal padding for each size.
- Base spacing on 4, 8, 12, 16, 24, 32 and 48 px. Use 8–12 px for related controls,
  16–24 px for content insets and 24–32 px between sections. Preserve purposeful
  optical offsets rather than rounding every number mechanically.
- Define whether alignment follows the container edge, icon slot or text column.
  Keep catalogue checkboxes, logos, copy and source actions in predictable slots.
  Reserve consistent source-action space so translated labels do not crowd names.
- Apply one heading/inset convention to comparable panels. In Review, either
  align both headings as section headings or align their content baselines inside
  comparable containers.
- Keep glass depth semantic: broad windows are quiet, controls are distinct, and
  menus/dialogs/floating summaries are denser. Do not change opacity arbitrarily
  between unrelated hover rules.

## Motion proposals

Keep the liquid character, crisp text, native scrolling and bounded window motion.
Define three shared presets: immediate feedback, elastic surface response and
spatial/selection transition. A useful starting range is 100–150 ms for feedback,
200–300 ms for ordinary surface response and 300–400 ms for larger transitions.
Tune springs by perceived settling and interruption, not duration alone.

Primary, secondary and tertiary actions can share a curve while differing in
amplitude. Related windows/navigation can keep the current 4 px bound. Deform the
surface independently of labels and hit targets. Functional movement settles;
new input retargets the current state rather than queuing a second animation.
Keep Calm and system accessibility overrides authoritative.

## Source findings

- `docs/assets/style.css` declares category radii at 16 px and source-option radii
  at 17 px, but the broad action selector in `docs/assets/liquid.css:110` sets
  their radius to 24 px. Geometry should have one owner; the motion layer should
  consume that geometry rather than silently redefining it.
- Control heights currently include 32 px text actions, 38 px source triggers,
  40 px effects/actions, 44 px icons/navigation and 46 px primary/secondary
  actions. Some size variation is intentional, but it should be named by density
  and importance rather than emerging from individual selectors.
- The confirmation appearance is separate from catalogue checkbox decoration:
  `docs/assets/style.css:1351` and `docs/assets/liquid.css:273`. Reuse the visual
  checkbox family while preserving native input semantics.
- Motion tokens exist, but literal durations and easing values are still repeated
  in individual rules. Centralise presets and explicitly document exceptions.

## Suggested implementation order

1. Create a small internal component reference using the real controls, including
   all meaningful states, both themes, Calm and long translations. No new framework
   or component-library dependency is needed.
2. Consolidate radius, size, spacing and material tokens, then remove conflicting
   geometry overrides. Unify confirmation and catalogue checkboxes.
3. Apply the shared state and motion contracts, then align the affected panels.
4. Verify keyboard focus, interruption, disabled/busy behaviour, layout stability,
   compact widths and translated labels. Update existing browser checks where the
   observable contract changes.

## Evidence limits

This run inspected the current desktop choices, guide and review screens plus
their source styles. It did not rerun the automated suites, independently exercise
every hover/press state, re-audit phone layouts or test VoiceOver/touch hardware.
Those are acceptance checks for an implementation pass, not established results
of this review. An early capture during smooth scrolling was rejected and replaced
by the settled Review screenshot shown above.
