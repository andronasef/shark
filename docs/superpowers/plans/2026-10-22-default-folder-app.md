# Default Folder App Implementation Plan

**Goal:** Introduce Shark in a three-step first-run welcome, offer optional default-folder-app and Full Disk Access setup, and retain these actions in Settings.

**Architecture:** Use `NSWorkspace` with `UTType.folder` for associations, an observable main-actor service for status and changes, and the existing single workspace for incoming folder URLs. Use a native SwiftUI sheet for the three-step welcome after the main window becomes visible.

**Constraints:** Swift 6, macOS 14+, no dependencies. Only folders are registered; packages and individual files retain their normal applications. Finder-specific reveal actions and system file dialogs retain their current behavior.

- [x] Add tests for incoming existing/new/multiple folders, split-pane reuse, invalid URLs, and package rejection. Implement routing in `WorkspaceState` and delegate URL handling in `SharkApp.swift`; reopen the single main window when necessary.
- [x] Add a tested `DefaultFolderAppService` for querying/changing the association and verifying actual results even after errors. Cover success, unchanged association, unknown status, retries, and request errors with injected system operations. A separate `OnboardingState` persists presentation and supports manual reopening.
- [x] Register `public.folder` with Editor role and Alternate rank in `Resources/Info.plist`. Refresh this plist on every dev bundle build.
- [x] Show Welcome → Features → Setup once after the main window becomes ready. Allow Back, Continue, Skip Setup, and Start Using Shark; add Help › Welcome to Shark for manual replay. Setup offers Make Shark Default and a Full Disk Access settings link with manual instructions. Already-default users still get the introduction. Add current default, Make Shark Default, and Restore Finder in Settings › General, plus Full Disk Access guidance in Settings › Privacy. Refresh on activation and disable association controls during a request.
- [x] Update `CHANGELOG.md`, `DESIGN.md`, and `website/src/data/features.ts` in this change.
- [x] Run `swift test`, `bash scripts/run.sh`, and website `npm run build`. Check native launch prompt, dismissal persistence, Settings, incoming folders while running and after window closure/cold launch. Check the website feature entry at desktop and mobile sizes.

**Review focus:** Hidden secondary panes must not be silently selected; locked tabs must not be navigated away; duplicate folder events must not add tabs; failed or cancelled consent must not show success; launch and restoration must not swallow incoming URLs.

## Verification findings

- On this macOS 26.6.2 machine, NSWorkspace and Launch Services both reject changing `public.folder` with NSOSStatus `-50`; even setting Finder to itself fails, while a same-current plain-text default succeeds. Preserve the existing default and show a manual setup option; do not imply a successful switch.
- Manual instructions add a user folder association and require restarting macOS. They may not work on every version; keep status tied to the live OS association. The folder preference recipe follows the [ForkLift manual](https://www.binarynights.com/manual#default-file-viewer), omitting `NSFileViewer` because Shark does not implement Finder reveal events. The UI only copies commands, never runs them.
- Capturing active navigation in ContentView’s parent body keeps toolbar paths synchronized when an external open event selects an existing tab.

**Validation:** 173 Swift tests passed, dev build launched, website production build passed, plist validated, packaging guardrails passed. Native checks covered all welcome steps, one-time persistence, Settings, Full Disk Access deep link, incoming multiple/repeated folders, and document-triggered cold launch. Website desktop/mobile DOM layout has no horizontal overflow. Default association remains Finder because this host rejects the APIs; manual commands were not executed or verified across a macOS restart.
