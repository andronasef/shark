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

## Rules

- Add a `CHANGELOG.md` entry (Added / Changed / Fixed) for any meaningful change.
- Update `DESIGN.md` when a measurement, spacing, or interaction rule changes.
- Commit one feature or fix at a time with a conventional message (`feat(area): ...`, `fix(area): ...`).
- Do not add a dependency for something a few lines of Swift or AppKit can do.
