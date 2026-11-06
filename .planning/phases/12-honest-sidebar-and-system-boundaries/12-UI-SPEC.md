---
phase: "12"
slug: "honest-sidebar-and-system-boundaries"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-06"
---

# Phase 12 — UI Design Contract

## Design System

| Property | Value |
|----------|-------|
| Tool | none — native SwiftUI/AppKit and existing Astro CSS |
| Preset | Not applicable |
| Component library | Existing first-party views; no added package |
| Icon library | Existing SF Symbols; no new icon required |
| Font | macOS system font; website system stack |

Authority: `12-CONTEXT.md`, `PRODUCT.md`, root `DESIGN.md`, and `website/DESIGN.md`. This is a removal and explanatory-copy phase. Preserve existing appearance; do not restyle the sidebar, welcome, Help, or website.

## Surfaces and Interaction

- **Places sidebar:** remove the entire Tags section, seven color-name filter buttons, and inert All Tags button. Remove their independent Up/Down focus-order entries too. No placeholder, disabled heading, extra gap, or replacement control remains. Favorites, Tab Groups, Locations, tree, mounted-volume eject, and existing focus/collapse behavior remain intact.
- **Help:** add an explanatory section between Explore Shark and Mouse, using the existing section stack. It contains a heading and static text, with no action.
- **Welcome:** add the limitation directly below Default Folder App controls on the setup step, inside the existing scrollable body. Footer and controls retain their positions and behavior.
- **Website:** revise the existing Finder-replacement FAQ answer and default-folder-app catalog description to state the same boundary. Remove the catalog's claim that Folder Tree replaces Tags. Existing FAQ disclosure and catalog layout remain unchanged; no planned Finder-tag feature claim is added.
- **Documentation:** update root DESIGN's Places-style wording to omit absent Tags and state that only functional sidebar controls participate in keyboard traversal. No mouse binding changes are introduced.

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| sm | 8 pt | Existing setup group spacing |
| md | 16 pt | Existing feature-row spacing, retained |
| lg | 24 pt | Existing Help section separation |
| xl | 32 pt | Existing welcome body insets |

Inherited exceptions, retained rather than redesigned: Help subsection spacing is 6 pt and Help content inset is 28 pt; welcome setup section spacing is 20 pt. Sidebar retains 32 pt rows, 14 pt labels, 22 pt icon slots, 170/210/280 pt min/ideal/max widths, and existing section metrics. No new measurement is needed. Website spacing and responsive breakpoints remain exactly those in `website/DESIGN.md` and existing CSS.

## Typography

The four relevant native roles use regular and semibold weights only. Semantic SwiftUI styles remain authoritative so accessibility and macOS adaptation are preserved.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Existing small setup text | 12 pt / `.caption` | regular | System default |
| Added explanatory text | 13 pt / `.callout` | regular | System default; natural wrapping |
| Existing sidebar labels | 14 pt | regular | Existing 32 pt row |
| Added Help section heading | 15 pt / `.title3` | semibold | System default |

Website text uses existing FAQ/catalog styles: descriptions 14 px, line-height 1.8; titles 15 px with existing weight. No CSS typography change is authorized by this phase.

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (approximately 60%) | System window background; website `#f7f9fc` | Existing content canvas |
| Secondary (approximately 30%) | Existing adaptive sidebar material; website neutral surfaces | Existing chrome and supporting text |
| Accent (at most 10%) | System accent; website `#0069d4` | Existing selected/focused controls and links |
| Destructive | System destructive color | No new destructive action |

These proportions describe existing hierarchy, not a new painted allocation. Added native explanatory text uses `.secondary`, its heading `.primary`. Accent remains reserved for existing selection, focus outlines, links, and primary welcome button. No tag-color dots remain until actual Finder tags ship.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Help heading | Shark and system dialogs |
| Help and welcome explanation | Other apps use macOS Open and Save dialogs. Making Shark your default folder app does not replace those dialogs. |
| Website FAQ | Append the same factual boundary to the existing “Does Shark replace Finder?” answer, preserving its truthful default-app and Show in Finder explanation. |
| Catalog default-folder-app entry | Preserve implemented behavior and explicitly say other apps retain macOS Open/Save dialogs. |
| Catalog Folder Tree entry | “in place of Locations”; omit “and Tags” until real tags are implemented. |
| Primary CTA | No new CTA; retain Continue / Start Using Shark and existing default-app controls. |
| Empty state | No new empty state. Absence of Tags renders nothing and consumes no keyboard stop. |
| Error state | No new failing operation; preserve existing default-app errors and permissions guidance. |
| Destructive confirmation | None; removal affects presentation only, not files or saved favorites. |

Use `L10n.text` for native added copy, following current localization fallback behavior. Do not translate paths, identifiers, or storage keys. Do not imply that system dialogs, Finder reveal, or privacy permissions are controlled by Shark.

## UI Considerations

Applicable state considerations are specified for planning; the orchestrator owns the post-checker compiled probe/write-back.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| populated | Sidebar navigation | ✅ covered | Visible Favorites, optional Tab Groups, and Locations/tree retain current layout and activation. No Tags controls appear in either style. |
| empty | Removed tag list | ✅ covered | Render neither heading nor empty placeholder; keyboard traversal contains no Tags identifiers. |
| partial | Sidebar sections | ✅ covered | Collapsed sections omit child focus stops; removing Tags does not change other section expansion or folder selection. |
| zero-one-many | Favorites and volumes | ✅ covered | Preserve existing zero, one, and many-item behavior without changing data or row rendering. |
| loading/error | Existing navigation and default-app controls | ✅ covered | Preserve existing asynchronous states and failures; static explanatory copy neither changes state nor asserts success. |
| overflow | Help and welcome | ✅ covered | Added copy wraps vertically within existing scrollable content; welcome footer remains outside the scroll body. |
| long-text | Added static content | ✅ covered | Use multiline text with natural wrapping and no line limit; retain existing native scroll containers. |
| overflow | Website FAQ and catalog | ✅ covered | Existing responsive layout wraps descriptions; FAQ remains one column at 800 px and below and catalog entries one column at 540 px and below. |

## Verification Contract

- In the running native app, inspect Places and Folder Tree sidebar styles. Confirm Tags/All Tags are absent; exercise Up/Down through the final visible section and confirm no invisible focus stop. Activate a surviving place/favorite and check collapse behavior without mutating user files.
- Open Help and the welcome setup step. Read the limitation in each; inspect wrapping and scrolling at the existing minimum window sizes. Do not operate system privacy dialogs or change default-folder associations for this copy check.
- Run `swift build`, `swift test`, and `npm run build` in `website/`.
- Inspect the built features page at desktop (approximately 1440 × 900) and mobile (390 × 844) and open the revised home FAQ. Confirm readable wrapped text, no horizontal overflow, working disclosures, and no absent-tag claim. Use permitted browser tooling; record any unavailable check honestly.

## Registry Safety

Not applicable. No component registry, third-party block, dependency, remote font, or new network integration.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS — Tool: none; installed-package inventory not applicable

**Approval:** approved by independent phase12_ui_check, 2026-11-06.

Visual anchors remain existing section headings in Help/welcome and existing page headings on the website. No new dominant element.
