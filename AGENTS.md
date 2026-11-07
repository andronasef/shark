# Shark

Native macOS file manager (Swift 6, SwiftUI with AppKit bridges, macOS 14+). Product direction is in `PRODUCT.md`; the visual system is in `DESIGN.md`.

## Build, run, test

- `swift build` builds; `swift test` runs the suite (keep it green).
- `bash scripts/run.sh` builds, bundles `Shark.app`, re-signs it ad hoc, and relaunches. The ad hoc signature changes on every build, so macOS asks again for Documents/Downloads access after each run. Answer the prompt yourself; do not script it.
- Check UI changes in the running app. A passing build is not proof that a view looks or behaves right.

## Where things live

- `Sources/Shark/State` observable models (`WorkspaceState`, `NavigationState`).
- `Sources/Shark/Services` file system, clipboard, settings, previews.
- `Sources/Shark/Views` SwiftUI views, grouped by area (Directory, Navigation, Sidebar, Workspace, Settings, Help).
- `Tests/SharkTests` unit tests. Add one for any non-trivial logic.

## Help page (keep it in sync)

The in-app **Help › Shark Help** window (`Sources/Shark/Views/Help/HelpView.swift`) is the authoritative list of what the mouse does, grouped by where the pointer is. `MouseHelp.zones` is the data. It already holds every mouse binding and its zone, so read it before changing or adding a binding, and update it in the same change. Optional mouse behaviours are switched in Settings › Mouse (`MouseSetting` in `Services/MouseSettings.swift`) and default to on.

## Website features page (keep it in sync)

The website’s **Features** page (`website/src/pages/features.astro`, published at `/shark/features/`) is the complete public inventory of implemented, user-facing Shark capabilities. Its content lives in `website/src/data/features.ts` (`featureGroups`). Read that catalog before adding or changing a feature.

- Add every new user-facing feature to the appropriate catalog category **in the same change** as its implementation. Cover smaller capabilities, settings, and mouse or keyboard interactions as well as headline features.
- Update the existing entry when behavior, availability, a shortcut, or a setting changes. Remove or revise entries when a feature is removed; do not leave stale claims.
- Describe only implemented behavior, verified against the app source. Do not list roadmap items or disabled placeholders as available features.
- Keep related shortcuts and platform requirements accurate. Mouse-binding changes must update **both** this catalog and `MouseHelp.zones`; the features page does not replace in-app Help.
- Keep the home page’s selected highlights consistent when a change affects them. Run `npm run build` in `website/` and check the features page at desktop and mobile sizes after content or layout changes.

## User Changelog & Release Notes (keep it in sync)

Every release in `CHANGELOG.md` maintains a `### User Changelog` section placed immediately below the version heading, before technical sections (`### Added`, `### Changed`, `### Fixed`).

### Principles for User Changelog:
- **Focus Strictly on What Matters to the User**:
  - Keep it tight: **3 to 5 highlights maximum** per release.
  - Highlight only noticeable performance wins, major workflow capabilities, or fixes for painful bugs that directly impact the user's daily experience.
  - **NEVER** include meta/internal items that users do not care about:
    - ❌ Rating / review prompts ("Rate us on App Store")
    - ❌ Share with friends / milestone celebratory cards
    - ❌ Telemetry, analytics, or crash reporting integrations
    - ❌ Minor translation or string updates
    - ❌ Minor UI wording, status bar tips, or internal refactors
  - Ask: *"Does a regular user actually care about this when opening the app or reading the App Store update notes?"* If not, put it in `### Added`, `### Changed`, or `### Fixed`, NOT in `### User Changelog`.
- **Short, Punchy, and Plain English**:
  - One concise sentence per bullet (15–20 words max).
  - Format: `- **Feature Name**: What it does and why it makes your work easier/faster.`
  - Zero technical jargon (no Swift types, internal symbols, architecture terms).
- **Single Source of Truth for All Release Channels**:
  The `### User Changelog` is the central source automatically distributed across:
  1. **Mac App Store "What's New in This Version"**: Extracted by `scripts/extract-release-notes.sh <version> --user-only` into `dist/appstore-whats-new.txt`.
  2. **In-App Update Alerts**: Rendered directly in Shark's update alert window.
  3. **GitHub Releases**: Featured at the top of the published release notes.

## Rules

- Add a `CHANGELOG.md` entry (Added / Changed / Fixed) for any meaningful change, and also update `### User Changelog` with 3–5 user-important, jargon-free highlights.
- Update `DESIGN.md` when a measurement, spacing, or interaction rule changes.
- Commit one feature or fix at a time with a conventional message (`feat(area): ...`, `fix(area): ...`).
- Do not add a dependency for something a few lines of Swift or AppKit can do.
