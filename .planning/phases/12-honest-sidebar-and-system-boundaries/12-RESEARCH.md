# Phase 12: Honest Sidebar and System Boundaries — Research

**Researched:** 2026-11-06
**Domain:** Existing SwiftUI sidebar and product copy
**Confidence:** HIGH for directly read source findings; no external technology assumptions

<user_constraints>
## User Constraints (from CONTEXT.md)

<!-- DATA_b7c39a21_START -->
### Sidebar
- Remove the Tags section, color-name filters and inert All Tags action, including keyboard traversal entries.
- Preserve Favorites, Locations, tree, mounted-volume eject and collapse behavior.
### System boundary
- Help, onboarding and the website FAQ explain that other apps retain system Open/Save dialogs, even when Shark is the default folder app.
- Correct catalog references to absent Tags without adding future feature claims.
### Implementation discretion
- Use existing native text styles and layout, no new controls or dependencies. Approved decisions in EVERYDAY-MAC-MILESTONE.md supersede repeated grilling.

### Deferred Ideas
Actual Finder tags remain scheduled for Phase 19, not deferred from the milestone.
<!-- DATA_b7c39a21_END -->
</user_constraints>

## Project Constraints (from AGENTS.md)

- Build with `swift build`; keep `swift test` green. Add meaningful tests for non-trivial logic. [VERIFIED: AGENTS.md, Build/run/test and Rules]
- Check visible changes in the running native app. `bash scripts/run.sh` re-signs/relaunches; system privacy prompts belong to the user and must not be scripted. [VERIFIED: AGENTS.md, Build/run/test]
- Read MouseHelp before binding changes; update its affected bindings in the same feature commit. Existing sidebar folder mouse bindings are unchanged by removing the fake tag controls. [VERIFIED: AGENTS.md, Help page; Sources/Shark/Views/Help/HelpView.swift:77-90]
- Update the implemented-only feature catalog, relevant home highlights, changelog and changed design rules in the same conventional feature/fix commit. Build the website and inspect Features at desktop/mobile sizes. No dependency is needed. [VERIFIED: AGENTS.md, Website features page and Rules]

<phase_requirements>
## Phase Requirements

| ID | Required behavior | Research support |
|---|---|---|
| HON-01 | Remove false Finder tags and their keyboard stops | Three coordinated removals below |
| HON-02 | Explain other apps' system Open/Save dialogs in Help, onboarding and FAQ | Existing copy insertion points below |

Requirement descriptions verified against `.planning/REQUIREMENTS.md:13-14`.
</phase_requirements>

## Summary

Use a small deletion and copy correction. The fake controls are entirely local to the sidebar; their keyboard projection is separate and must be removed too. The public catalog already states the Open/Save limitation under default-folder setup, but the FAQ, Help and welcome need equivalent visible wording. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:27-35,168-217,433-460; website/src/data/features.ts:155; Sources/Shark/Views/Help/HelpView.swift:105-123; Sources/Shark/Views/Onboarding/OnboardingView.swift:75-86; website/src/pages/index.astro:17-24]

**Recommendation:** One feature-sized fix commit covering sidebar removal and honest product copy; do not introduce a temporary tag model, placeholder heading or new navigation infrastructure.

## Architectural Responsibility Map

| Capability | Primary owner | Secondary owner | Rationale |
|---|---|---|---|
| Visible sidebar controls | SwiftUI view | Existing section component | Rendering and keyboard order are in the view |
| System-boundary explanation | Help/welcome copy | Website FAQ/catalog | No system registration behavior changes |

Ownership verified by the source locations in Summary.

## Standard Stack / Don't Hand-Roll

Keep existing SwiftUI/AppKit and Astro. This phase installs no packages or changes runtime APIs. The package declares `// swift-tools-version: 6.2` and `.macOS(.v14)`; these are baseline declarations, not a toolchain upgrade request. [VERIFIED: Package.swift:1-9,16-29]

## Architecture Patterns and Exact Edit Sites

1. Delete the `tagItems` property and its color tuples. Verbatim identifiers/values: `private let tagItems: [(name: String, color: Color)]`, `"Red"`, `"Orange"`, `"Yellow"`, `"Green"`, `"Blue"`, `"Purple"`, `"Gray"`. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:27-35]
2. Delete the complete rendered Tags section. Verbatim existing behavior: `SidebarSectionGroup("Tags", focus: $sidebarFocus)`, `navigationState.filterText = tag.name`, `Button(action: {})`, `Text(L10n.text("All Tags..."))`. Preserve the surrounding `if !isTree` closing brace. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:155-218]
3. Delete the independent focus-order entries. Verbatim: `order.append("Tags:header")`, `if expanded("Tags")`, `order += tagItems.map { "Tags:" + $0.name }`, `order.append("Tags:all")`. Preserve Locations and final focus clamping. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:433-460]
4. Correct the adjacent comment and Settings description, which still say `"Folder Tree shows an expandable list of folders, like File Explorer, in place of Locations and Tags."`; change public catalog's matching `in place of Locations and Tags` phrase and DESIGN's Places description. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:146; Sources/Shark/Views/Settings/SettingsView.swift:91; website/src/data/features.ts:47; DESIGN.md:29]
5. Add concise boundary copy beside Help's feature discovery block, in the welcome's introductory body or default-folder setup, and in the existing Finder FAQ. Existing Help uses `.font(.callout)` and `.foregroundStyle(.secondary)`; welcome body already uses `.fixedSize(horizontal: false, vertical: true)` inside a scrollable area. Reuse those patterns. [VERIFIED: Sources/Shark/Views/Help/HelpView.swift:109-116; Sources/Shark/Views/Onboarding/OnboardingView.swift:34-45,75-85,129-143; website/src/pages/index.astro:19]

## Common Pitfalls

- Removing only the visible section leaves invisible keyboard stops because `moveSidebarFocus` separately assembles its order. [VERIFIED: Sources/Shark/Views/Sidebar/PlacesSidebarView.swift:433-460]
- Do not erase all tag-related strings: tab tint is a separate capability, and actual tags are a later milestone phase. The scope is the false sidebar section. [VERIFIED: approved 12-CONTEXT.md decisions]
- No persistence migration is needed for the dormant collapse key: `SidebarSectionGroup` derives it from `"sidebar.section.\(title).expanded"`; leaving old preferences unused avoids altering unrelated defaults. [VERIFIED: Sources/Shark/Views/Sidebar/SidebarSectionGroup.swift:17-23]
- The FAQ feeds JSON-LD from the same `faqs` array, so edit that source once instead of duplicating structured data. [VERIFIED: website/src/pages/index.astro:17-28]

## Runtime State Inventory

| Category | Finding | Action |
|---|---|---|
| Stored data | Generic section collapse preference described above | Leave unused Tags key; no migration |
| Live service config | No service integration is changed by this view/copy phase | None in scope |
| OS-registered state | Default-folder association is not changed | None in scope |
| Secrets/env vars | No secret or environment-variable reads in the affected sidebar/copy blocks | None |
| Build artifacts | Running app must be rebuilt to reflect view deletion | Run existing bundler; never treat old app as evidence |

The inventory is bounded to the directly read affected files and approved scope; it is not an audit of external user state.

## Validation Architecture

Nyquist validation is enabled. [VERIFIED: .planning/config.json:24, verbatim `"nyquist_validation": true`]

| Requirement | Check | Method |
|---|---|---|
| HON-01 | No Tags/colors/All Tags in Places; arrow traversal stops on real controls; favorites/tree/collapse still work | Running native app via sole desktop controller; source removal audit |
| HON-02 | Boundary copy visibly readable in Help and welcome; FAQ states same limitation | Native UI plus website desktop/mobile inspection |
| Regression | Existing unit suite and builds remain green | `swift build`, `swift test`, `npm run build` with website working directory |

Commands come from AGENTS.md; website's script is verbatim `"build": "astro build"`. [VERIFIED: AGENTS.md, Build/run/test and Website features page; website/package.json:7]

Existing sidebar tests cover favorites and tree style; they do not assert this SwiftUI rendering/focus order. Avoid a source-text snapshot test or a new abstraction solely to test the deletion. If execution introduces non-trivial logic, add a meaningful behavioral unit test. [VERIFIED: Tests/SharkTests/SidebarFavoritesTests.swift; Tests/SharkTests/FolderTreeTests.swift:74-77; AGENTS.md, Rules]

## Security Domain

Security enforcement is enabled at ASVS level 1 with high findings blocking. Verbatim settings: `"security_enforcement": true`, `"security_asvs_level": 1`, `"security_block_on": "high"`. [VERIFIED: .planning/config.json:48-50]

This deletion/copy phase changes no authentication, session, access-control, file-write, crypto or external-input path. Preserve existing native authorization behavior; do not automate privacy dialogs during validation. [VERIFIED: approved 12-CONTEXT.md boundary; AGENTS.md, Build/run/test]

## Assumptions Log / Open Questions

No new technology assumptions or user decisions are needed. UI success and permission availability remain execution-time observations, not research claims. No build, tests or UI checks were performed by this research agent.

## Metadata

Local source was read directly in this research session. The generic confidence seam classifies the unrecognized provider name `local` as LOW; this is not evidence against the source-of-truth file observations, which are cited individually above. No package-install legitimacy gate or external documentation lookup is applicable.
