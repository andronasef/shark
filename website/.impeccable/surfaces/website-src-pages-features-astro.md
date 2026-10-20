---
version: 1
slug: "website-src-pages-features-astro"
primary_target: "website/src/pages/features.astro"
related_targets: ["website/src/data/features.ts","website/src/styles/features.css"]
---

# Full features page

Primary target: website/src/pages/features.astro. Mode: Read.
The user requests a complete features page and an AGENTS.md requirement to update it with every new feature, matching the existing in-app Help maintenance rule.

## Direction contract

THESIS: A complete, source-verified public feature inventory that remains easy to scan as Shark grows.
OWN-WORLD: Inherit website/DESIGN.md: cool white, slate, Mac system typography, restrained structural glass, blue links and existing real app screenshots.
STORY: Browse eight stable categories, understand implemented features and shortcuts, and download the app. No roadmap items or disabled placeholders.
FIRST VIEWPORT: Shared glass navigation, a split introduction with a real screenshot, and the beginning of the category index and catalog. Desktop catalog has a sticky index and two-column definition lists; mobile index flows above single-column entries.
FORM: Extend the established website with a readable catalog and shared cross-page navigation. The precise user request and existing design settle this extension; no new visual-world roll or comp is required.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Maintenance authority: featureGroups in website/src/data/features.ts is the website inventory. MouseHelp.zones remains the mouse-binding authority. AGENTS.md requires same-change updates to both when relevant.

## Verification

Production build passed with two static routes. Browser checks at 1440, 768, 390, and 320px showed 64 entries across eight categories, no overflow, all images loaded, unique IDs, and valid anchors. Category jumps, home/features/FAQ navigation, and navigation without JavaScript passed. No app source changed.

Independent finish review identified two copy corrections: document the Subfolder Tip preference and clarify that windows share a workspace. Both were resolved. Source checking also removed startup/view-default and tab-preference claims whose settings are not connected to behavior. Replacement captures and repeated browser checks passed; the bounded review verdict was `ship`, with all scored fixes resolved and no batch regressions. The detector reported advisory token-coverage findings only; pre-existing design-token drift was not repaired as a side effect.
