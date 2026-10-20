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

## Rules

- Add a `CHANGELOG.md` entry (Added / Changed / Fixed) for any meaningful change.
- Update `DESIGN.md` when a measurement, spacing, or interaction rule changes.
- Commit one feature or fix at a time with a conventional message (`feat(area): ...`, `fix(area): ...`).
- Do not add a dependency for something a few lines of Swift or AppKit can do.
