# Third-party notices

## Transitions.dev

Copyright © 2026 Jakub Antalik / Transitions.dev.

The modal transition in `assets/liquid.css` is from the free
[Modal open / close](https://transitions.dev/detail.html?t=modal-open-close)
snippet. The motion token scale and other interaction treatments were informed
by the [Transitions.dev skill](https://github.com/Jakubantalik/transitions.dev/tree/main/skills/transitions-dev).
The checkbox treatment adapts the stroke-draw pattern to existing native inputs.

The [Transitions.dev licence](https://github.com/Jakubantalik/transitions.dev/blob/main/LICENSE)
permits using, modifying and shipping transitions inside personal and commercial
products. It restricts redistribution of the library itself as a competing
collection. mac-setup includes only the transition it uses, not the library or
its paid components. The source comment is retained. A copy of the upstream
licence is in [licenses/transitions-dev.txt](licenses/transitions-dev.txt).

## Liquid Acrylic research

Pedro supplied `liquid-acrylic-manual.md` and `liquid-acrylic-source.zip` as design
and engineering references. Their layer separation, spring/damping model and
area-preserving surface stretch informed the original implementation in
`assets/liquid*.mjs`. The standalone lab, its AGENTS.md, executable scripts,
generated distribution and third-party library references are not vendored.

## Wallpaper

`assets/aurora.png` is a generated, project-local background asset. Its prompt
and the interface concept briefs are recorded in `outputs/design/liquid/`.
No third-party font or image service is contacted at runtime.

## Application and brand artwork

The five round language flags in `assets/flags/` are original, project-local SVG
drawings of national flag motifs. They use no icon API, external font or image
service and are included with the project's own artwork under its MIT licence.


The catalogue bundles **77 icon assets for 88 entries**. They are used only to
identify the respective software and services. Product names and trademarks remain
with their owners; inclusion does not imply endorsement. These assets are not
relicensed by mac-setup’s MIT licence.

- 23 genuine macOS application icons were extracted from already installed,
  named application bundles and converted from ICNS to 128 px PNG. The application
  name, public cask source, version and original resource name are recorded.
  Local usernames, absolute paths and account information are not included.
- 23 Apple artwork assets cover all 22 catalogue App Store IDs and full Xcode.
  They were retrieved using Apple’s documented
  [ID lookup API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/LookupExamples.html).
  Non-PNG artwork was decoded to PNG without changing its visual content.
  Artwork remains the property of the respective app developers.
- 27 additional brand marks come from
  [Dashboard Icons](https://github.com/homarr-labs/dashboard-icons), revision
  `320c819da84048d5a3066e2578bfa83be9019fdf`, under its
  [Apache-2.0 collection licence](https://github.com/homarr-labs/dashboard-icons/blob/320c819da84048d5a3066e2578bfa83be9019fdf/LICENSE).
  A copy is retained in [licenses/dashboard-icons.txt](licenses/dashboard-icons.txt).
  Copyright and trademark rights in the depicted brands remain with their owners.
  SVG sources were checked for active content and external resource references.
- Four assets come directly from the official Inkscape, OBS Studio, TeamViewer
  and Apple SF Symbols websites. They remain their respective owners’ artwork.

Exact per-file URLs, source type and SHA-256 checksums are in
[the icon manifest](assets/icons/manifest.json). The generated local item mapping
is `assets/app-icons.mjs`; icon updates do not change installer selections or
catalogue versions. When refreshing artwork, retain source notices, verify the
new file, update its manifest checksum and mapping, and inspect both themes.
Use a category symbol when identifying artwork is unavailable. Do not fabricate
lookalike logos or introduce browser calls to a third-party icon API.
