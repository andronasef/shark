# Phase 12: Honest Sidebar and System Boundaries - Pattern Map

**Mapped:** 2026-11-06
**Files analyzed:** 8 existing files; no new runtime files
**Analogs found:** 8 / 8 (existing-file edits)

## File Classification

| Modified file | Role | Data flow | Closest analog | Match |
|---|---|---|---|---|
| `Sources/Shark/Views/Sidebar/PlacesSidebarView.swift` | component | event-driven | Its existing Locations rendering and `moveSidebarFocus(by:)` | exact |
| `Sources/Shark/Views/Help/HelpView.swift` | component | transform | Its Explore Shark copy block | exact |
| `Sources/Shark/Views/Onboarding/OnboardingView.swift` | component | event-driven | Its `welcome` and `setup` content | exact |
| `Sources/Shark/Views/Settings/SettingsView.swift` | component | event-driven | Its Sidebar section explanatory caption | exact |
| `website/src/data/features.ts` | model | transform | Existing `folder-tree` and `default-folder-app` feature records | exact |
| `website/src/pages/index.astro` | component | transform | Existing `faqs` array and `faqJsonLd` projection | exact |
| `DESIGN.md` | config/documentation | transform | Existing sidebar behavior bullets | exact |
| `CHANGELOG.md` | config/documentation | transform | Existing Keep a Changelog sections | exact |

All analog paths above were confirmed tracked with `git ls-files -- <paths>`; no runtime mirrors are referenced.

## Pattern Assignments

### Sidebar removal and focus order

**Analog:** `Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:433–460`.

Keep the existing imperative visible-control projection; remove only tag entries. The remaining Locations behavior is:

```swift
order.append("Locations:header")
if expanded("Locations") { order += locations.map { "Locations:" + $0.url.path } }
```

Its final focus lookup/clamping remains unchanged:

```swift
let current = sidebarFocus.flatMap { order.firstIndex(of: $0) } ?? (offset > 0 ? -1 : order.count)
sidebarFocus = order[max(0, min(current + offset, order.count - 1))]
```

Remove `tagItems`, the rendered `SidebarSectionGroup("Tags", ...)`, and the separate `Tags:header` / `Tags:all` projection together. Do not replace them with disabled controls or introduce a second navigation model. Preserve Favorites, tree, Tab Groups and Locations branches. The adjacent comment at line 146 should describe the remaining sections truthfully.

### Help explanatory copy

**Analog:** `Sources/Shark/Views/Help/HelpView.swift:109–116`.

```swift
VStack(alignment: .leading, spacing: 6) {
    Text(L10n.text("Explore Shark"))
        .font(.title3.weight(.semibold))
    Link(L10n.text("All Features"), destination: AppLinks.features)
    Text(L10n.text("Browse the complete features list, including shortcuts and settings, on the Shark website. You can also find it in Help → All Features."))
        .font(.callout)
        .foregroundStyle(.secondary)
}
```

Use this native text hierarchy for the Open/Save boundary. The outer content already scrolls and uses 24 pt block spacing. This phase adds explanation, not a new action or mouse binding.

### Welcome explanatory copy

**Analog:** `Sources/Shark/Views/Onboarding/OnboardingView.swift:75–85`.

```swift
Text(L10n.text("Browse local folders and mounted drives, organize files, and pick up where you left off. Your tabs and layout are remembered."))
    .font(.body)
    .foregroundStyle(.secondary)
    .fixedSize(horizontal: false, vertical: true)
```

Reuse `L10n.text`, secondary text and vertical wrapping within the existing scrollable body. The setup area at lines 129–143 is another existing insertion point beside `DefaultFolderAppControls()`. Keep the 580 × 560 pt welcome frame and existing footer intact.

### Settings caption correction

**Analog:** `Sources/Shark/Views/Settings/SettingsView.swift:85–92`.

```swift
Text(L10n.text("Folder Tree shows an expandable list of folders, like File Explorer, in place of Locations and Tags."))
    .font(.caption).foregroundColor(.secondary)
```

Correct only the stale Tags claim, retaining the existing caption style and picker behavior.

### Public inventory and FAQ

**Analogs:** `website/src/data/features.ts:47,155`; `website/src/pages/index.astro:17–28`.

The feature catalog is data, not duplicate page markup:

```typescript
{ id: 'folder-tree', title: 'File Explorer folder tree option', description: '...' },
```

Correct its existing description instead of adding a future-tags entry. The existing `default-folder-app` entry already says macOS Open/Save dialogs remain the system interface; keep this accurate and align welcome/Help/FAQ wording.

FAQ content uses one `faqs` array for rendering and structured data:

```typescript
const faqJsonLd = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: faqs.map(f => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a.replace(/<[^>]+>/g, '') } })),
};
```

Update the existing “Does Shark replace Finder?” answer in the array; do not separately author JSON-LD or introduce layout styles.

### Design and changelog

**Analogs:** `DESIGN.md:23–30`; `CHANGELOG.md:7–11`.

Keep design bullets factual about visible keyboard controls. Update the Places description that currently says “Locations and Tags”. Add this meaningful fix/copy change under `[Unreleased]` using `### Fixed` / `### Changed`; do not modify the public alpha version or create a release.

## Shared Patterns

- Native explanatory copy uses `Text(L10n.text(...))`, existing system typography and secondary foreground; filenames/paths are not involved.
- Focus order is manually projected from visible sections. Removal must affect rendering and projection atomically.
- No new auth, file-write, validation, async, or error path is introduced; no new dependency is appropriate.
- Preserve MouseHelp bindings: removing false tag buttons does not change the existing folder mouse gestures. Read/update MouseHelp if execution expands into an actual binding change.
- Build/test and real native UI checks are separate evidence. Website catalog changes require website build and desktop/mobile Features checks; no source-text snapshot test is needed for a deletion.

## No Analog Found

None. Every target is an edit to its existing owner, with no new runtime architecture.

## Metadata

**Search scope:** affected SwiftUI views, website data/home FAQ and root design/changelog.
**Strong analog groups:** 5 (sidebar; Help; welcome/settings; website data; documentation).
**Verification performed by mapper:** tracked-source checks and direct source reads only. No build, test or UI validation is claimed.
