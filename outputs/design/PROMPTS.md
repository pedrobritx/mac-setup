# Concept prompt set

Both references used the built-in `image_gen` tool with an opaque background.
These are the prompt briefs used for the main screen and its guided state; all
production text and controls were implemented in HTML/CSS/JavaScript.

## Main-screen prompt

Use case: ui-mockup. Create one precise senior product designer screenshot,
1536 × 1024 landscape, of the complete main desktop interface of mac-setup, an
open-source Mac app setup selector inspired by Ninite. Use restrained Apple
native UI, burgundy branding, a cool light background, white surfaces, dark ink,
muted grey text, fine borders, and no floating blobs or gratuitous gradients.

Show the complete app viewport: header, intro, three-step journey, six radio
profile options, searchable app checklist, category sidebar, and selected summary.
Header: mac-setup, by BRITX, How it works, GitHub, theme control. Main copy:
“Make this Mac yours.” and “Your apps, your tools, your preferences. One thoughtful
setup.” Profile options: Essentials, Developer, Education, Productivity, Creative,
BRITX Choice; the latter is selected and described as Pedro’s personal setup.

Use a single row of six profile tiles. Below it place a narrow category sidebar,
a broad open checklist in two columns, and a right-hand Your setup panel. The
checklist has category headings, native checkboxes, small app marks, one-line
descriptions and install-source labels. Include Development, AI & design, and
Productivity continuation, with the requested developer/design applications.
The summary has app/tool, preference and connection counts, removable selections,
an App Store/purchase note, “Review setup”, and “Nothing installs until you
confirm.” End with “No account. No tracking. Just your Mac.” Keep code-native
controls, precise hierarchy and generous readable spacing. No unrelated metrics,
marketing sections or hero eyebrow labels.

## Guided-state prompt

Use the saved main-screen concept as a reference. Create a new 1536 × 1024
screenshot of the guided installation state of that same app. Preserve its
header, native typography, cool light background, burgundy accent, white panels,
fine borders and restrained Mac identity. Main copy: “Your setup, step by step.”
and “Keep this window and Terminal open. We’ll show what needs your attention.”
Mark the third journey step active.

The main column has Installation progress, a clearly labelled Dry-run preview,
truthful text stating that no apps/preferences are being changed, a progress bar,
step count, and vertical module timeline with completed/current/waiting states.
Include Command Line Tools, Homebrew and packages, App Store, Terminal and shell,
Node/Python, Mac preferences and Verification. Below it put a collapsible
Installer output area and the reminder that reports stay on the Mac.

The right rail has “A few things need you”, official guidance for Figma MCP,
VMware Fusion and App Store sign-in/ownership, a report download control, and
“Your passwords stay with you.” Match the first concept’s precise geometry and
icon treatment. Show the entire requested state; the design is an illustrative
preview, not proof of a real installation. The implementation must use actual
installer data rather than the illustrative counts in the concept.
