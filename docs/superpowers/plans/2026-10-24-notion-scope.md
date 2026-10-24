# Shark Notion Scope Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the eight agreed Notion fixes/features with native macOS behavior and verifiable completion criteria.

**Architecture:** Preserve SwiftUI/AppKit and SwiftTerm; repair event routing and session ownership rather than replacing the terminal. Keep drag selection, preview geometry, toolbar configuration, photo browsing, and localization independently testable. Share bounded thumbnail loading between directory views and photo viewing where practical.

**Tech Stack:** Swift 6, SwiftUI, AppKit, SwiftTerm, ImageIO/Quick Look, Swift Package Manager; Astro for the existing feature inventory.

**Spec:** [Agreed requirements](../specs/2026-10-24-notion-scope.md), plus repository PRODUCT.md and DESIGN.md.

**Required edge-case pass:** Each task also implements and verifies its corresponding bullet in the spec's “Pre-implementation edge-case and UX review.” These checks refine the task's acceptance criteria; they are not deferred polish. In particular, terminal prompt safety, drag target snapshots, byte-bounded image loading, content-level preview fitting, and literal path direction must be addressed before their owning tasks are complete.

## Global Constraints

- Native macOS file manager (Swift 6, SwiftUI with AppKit bridges, macOS 14+).
- Do not add a dependency for something a few lines of Swift or AppKit can do.
- Trash before deletion; never block the main thread on disk work.
- Meaningful logic gets tests; visible changes get running-app verification.
- Every feature/fix updates CHANGELOG.md and the website inventory; mouse bindings also update MouseHelp.zones; measurements/interactions update DESIGN.md.
- One feature or fix per conventional commit.

## Review Focus

- Mixed-direction, quoted, spaced, and non-ASCII paths must survive shell insertion, dragging, and localization unchanged (Tasks 1, 2, 8).
- Focus changes must not interrupt a shell, an interactive child process, or a partly typed command (Task 2).
- Async image loads must not reposition a preview offscreen or show a previous file's image (Tasks 3, 4, 7).
- Files disappearing or becoming unreadable during a batch or slideshow must produce truthful outcomes without data loss (Tasks 1, 7).
- Minimum-size windows, display changes, Arabic layout, and accessibility preferences must keep controls reachable (Tasks 4, 5, 7, 8).

## Delivery sequence and working method

Each numbered task is a separately reviewable subsystem, not one combined implementation commit. Split its acceptance groups into individual fixes/features when committing. Dependencies: 3 before 7; 5/6 before final UI translation in 8; viewer action from 7 extends the menu organization established in 6. All other reliability work is independently deliverable.

For every task: add the meaningful regression first, observe failure, implement, run the focused tests, then run swift build and swift test. Launch with bash scripts/run.sh for visible checks; answer macOS permission prompts manually. Record actual results rather than treating this plan as evidence of passing checks.

## Task 1: Multi-selection drag and safe moves

**Files:** Modify Sources/Shark/Views/Directory/{DirectoryView,DetailsTableView,IconsGridView,MillerColumnsView}.swift and relevant sidebar drop handlers; retain Services/FileOperationsService.swift and State/NavigationState.swift safety semantics. Create Sources/Shark/Services/FileDragSelection.swift and Tests/SharkTests/FileDragSelectionTests.swift as focused helpers/tests if needed.

**Interface:** Proposed pure helper `FileDragSelection.urls(dragged: URL, selected: Set<URL>, ordered: [URL]) -> [URL]`; returns selected URLs in visible order when dragged is selected, otherwise only dragged. A real multi-file pasteboard payload, not one URL plus a misleading badge, reaches existing drop APIs.

- [ ] Add regression assertions: selected A/B dragged via A produces [A,B]; unselected C produces [C]; filenames with Arabic/spaces/quotes remain exact.
- [ ] Run `swift test --filter FileDragSelectionTests`; require a failing assertion or missing helper before implementing.
- [ ] Implement selection-aware native drag payloads and consistent destination resolution. Match selection behavior to each view's existing capabilities; keep the service's transaction/Undo protection.
- [ ] Run focused tests and DataSafetyTests/ExplorerServicesTests; add missing-target, collision, second-item failure, descendant, and Undo coverage where absent.
- [ ] Manually drag several selected items in Icons/List and supported Columns/Gallery selection paths to folders, background, sidebar folders, and the other pane. Verify Option/Command and cross-volume behavior on an available test volume; report unavailable scenarios.
- [ ] Apply documentation gate below and commit `fix(files): drag the selected files as one batch`.

## Task 2: Real terminal interaction and session lifetime

**Files:** Modify Sources/Shark/Terminal/{TerminalView,PTYSession,TerminalDrawerContainerView,TerminalOpener,TerminalMenuItems}.swift; State/WorkspaceState.swift; Views/Directory/DirectoryView.swift; Services/SharkSettings.swift; Tests/SharkTests/{TerminalKeyboardTests,TerminalOpeningTests,TerminalTests}.swift.

**Interface:** Window-owned PTYSession; terminal keyboard ownership follows the AppKit first responder. Proposed `PTYSession.useDirectory(_ directory: URL)` is an explicit idle-shell action, replacing automatic sync call sites. Do not send Ctrl-U or cd into active input or foreground programs; disable the action when safe execution cannot be established. Store terminal font size using a stable numeric preference (default 12 pt, implementation bounds 8–36 pt).

- [ ] Add regressions for terminal-focused arrows and Cmd ±/0 leaving directory state unchanged; directory-focused controls still work. Add tests that ordinary browsing produces no injected terminal input.
- [ ] Run `swift test --filter Terminal`; verify new regressions fail before repairs.
- [ ] Repair responder routing, shell focus on open, focus return on file click, and font zoom/reset. Use the existing SwiftTerm terminal rather than reimplementing line editing/history.
- [ ] Move process ownership/lifetime out of conditional drawer view construction so hiding preserves the same shell and scrollback. Handle natural shell exit, explicit restart/termination, and window teardown; keep metadata truthful.
- [ ] Preserve partly typed commands on Use Current Folder: detect a supported idle prompt or require explicit restart/open-at-folder rather than guessing from foreground process group alone. Test quoted/mixed-direction paths and unavailable directories.
- [ ] Verify shell history, cursor editing, Tab, Ctrl-C/D/Z, selection, Cmd-C/V/A, scrollback, clear, resizing, and font zoom. Exercise vim/less/top, a long-running command, hide/reopen, tab/pane switching, and two windows. Verify resize informs the PTY and causes correct terminal redraw.
- [ ] Apply documentation gate and commit the focus, font, and lifetime fixes separately with `fix(terminal): ...` messages.

## Task 3: Large photo-folder scrolling

**Files:** Inspect/modify Services/{ThumbnailService,FileSystemService}.swift; State/NavigationState.swift; Views/Directory/{IconsGridView,DetailsTableView,FileItemIconView}.swift. Add Tests/SharkTests/ThumbnailSchedulingTests.swift if scheduler logic changes.

**Interface:** Preserve existing thumbnail consumers; loading must have bounded concurrency/cache memory, deduplicate identical requests, and avoid stale results. Introduce a scheduler only if profiling confirms thumbnail pressure.

- [ ] Record baseline frame pacing/main-thread stalls, memory, thumbnail requests, and time to usable content in the 644-photo scenario (or a generated equivalent), plus 10k mixed entries and 100k lightweight entries in List. Separate initial load from warm scrolling.
- [ ] Identify the measured bottleneck: grid frame tracking, thumbnail decode/request churn, synchronous sorting/filtering, or event refresh. Save dataset/hardware/configuration so before/after is comparable.
- [ ] Add a failing regression for the confirmed cause: e.g. active request cap, cancellation freeing capacity, one result per file revision, or stale sort result rejection.
- [ ] Make the smallest measured repair; use thumbnail-sized decoding instead of full-resolution image retention for grids, and keep blocking I/O/decoding off the main actor.
- [ ] Rerun focused tests and the same profile. Acceptance: no repeatable scrolling stall over 100 ms after warm-up in the photo case, bounded cache/work, and no missing/stale thumbnails; investigate any remaining misses rather than declaring success from average FPS alone.
- [ ] Verify hover preview and selection during scrolling and a directory refresh. Apply documentation gate; commit `perf(directory): ...` naming the measured cause.

## Task 4: Screen-aware hover preview geometry

**Files:** Modify Views/Navigation/{HoverPreviewPanel,HoverPreviewCard}.swift; extend Tests/SharkTests/HoverPreviewTests.swift. Add Services/PreviewPlacement.swift for pure geometry if needed.

**Interface:** Proposed `PreviewPlacement.frame(anchor: CGPoint, desiredSize: CGSize, visibleFrame: CGRect) -> CGRect` in screen coordinates; all resulting edges stay within visibleFrame and width/height never exceed it.

- [ ] Add failing geometry assertions for each edge, negative-origin secondary displays, oversized content, and a delayed desired-size change.
- [ ] Run `swift test --filter HoverPreview`; verify the new geometry cases fail before implementation.
- [ ] Fit content and panel to usable screen bounds, recomputing after media loads and display changes; preserve aspect ratio and reachable controls.
- [ ] Run tests and manually check four corners, small displays/windows, multi-monitor arrangements when available, large portraits, text, video, and pointer handoff. Nonactivating behavior must preserve terminal/text focus.
- [ ] Apply documentation gate; commit `fix(previews): keep hover content within the usable screen`.

## Task 5: Native toolbar customization

**Files:** Modify Views/ContentView.swift and navigation chrome integration; create Services/ToolbarConfiguration.swift and Tests/SharkTests/ToolbarConfigurationTests.swift. Use an AppKit bridge only where supported SwiftUI APIs cannot provide the macOS 14 experience.

**Interface:** Stable item/group IDs with app-wide persisted configuration. Navigation, Location, and View remain coherent groups. Native customization/restoration controls use available platform APIs; restored IDs are validated against the current inventory.

- [ ] Add failing restore tests for saved ordering/visibility, unknown obsolete IDs, reset, and two windows observing one configuration.
- [ ] Run `swift test --filter ToolbarConfiguration`; observe failure before implementation.
- [ ] Implement add/remove/reorder and Restore Defaults, preserving action commands even when buttons are hidden. Exclude disabled tag editing from the available-action catalog.
- [ ] Replace fixed-width path allowances with sizing that reflects current toolbar composition and sidebar/window size.
- [ ] Verify native customization, relaunch persistence, two windows, 800×520 minimum size, sidebar toggling, overflow, macOS 14 compatibility, and newer macOS glass treatment. Run tests/build.
- [ ] Apply documentation gate; commit `feat(toolbar): support saved native customization`.

## Task 6: Context-sensitive menus

**Files:** Modify Views/Directory/DirectoryView.swift and existing action services; create Services/OpenWithService.swift and Tests/SharkTests/OpenWithTests.swift if needed. Share the existing native Share implementation from Views/ContentView.swift rather than duplicating behavior.

**Interface:** Open With resolves compatible applications using public NSWorkspace APIs and launches selected URLs explicitly; menus act on the clicked item or the preserved selection according to native selection rules.

- [ ] Add regression assertions for clicked selected/unselected targets, homogeneous/mixed selections, empty-space Paste, and compatible application lists.
- [ ] Run focused tests; confirm new action/selection cases fail before implementation.
- [ ] Organize Open/preview, terminal, clipboard, rename/duplicate/archive, path, Share, and Trash groups. Replace “Quick Preview (QT-03)” with plain language and distinguish Shark Preview from system Quick Look. Add Open With; omit unavailable tag editing.
- [ ] Check right-click on files/folders/multiselections/empty space in each view; verify keyboard equivalents and disabled states match actual capabilities, including missing files and no compatible alternate apps.
- [ ] Apply documentation gate; commit `feat(menus): expose context-sensitive file actions`.

## Task 7: Dedicated photo viewer and real Gallery previews

**Files:** Create Views/PhotoViewer/PhotoViewerWindowController.swift, PhotoViewerView.swift, and PhotoViewerState.swift; modify DirectoryView.swift, ThumbnailService.swift, settings, and image activation routing. Add Tests/SharkTests/PhotoViewerTests.swift. Retain Services/QuickLookCoordinator.swift Space behavior.

**Interface:** Proposed `PhotoViewerState(urls: [URL], initialURL: URL)` consumes an immutable snapshot in current filtered/sorted order, with explicit selected-only construction. State owns current index, zoom/pan/rotation, slideshow state and load generation; image loading shares bounded resources from Task 3.

- [ ] Add failing tests: ordered next/previous boundaries, selected-only population, missing/corrupt image fallback, cancellation/stale load rejection, and unchanged Space/default double-click routing.
- [ ] Run `swift test --filter PhotoViewer`; observe failures before implementation.
- [ ] Implement the dedicated window and explicit menu action. Add the opt-in image double-click setting; default false. Provide thumbnail strip, fit/actual-size zoom, pan, fullscreen, slideshow, metadata, and transient view-only rotation.
- [ ] Decode system-supported formats off the main thread; preserve animation for supported GIFs, respect image orientation, and cancel obsolete loads. Missing images show an explanation and permit moving to the next file.
- [ ] Replace Gallery's symbolic hero/strip with real previews using the same loading discipline. Preserve unsupported-file icon fallback.
- [ ] Verify JPEG/PNG/HEIC/TIFF/GIF, huge portraits, corrupt/disappearing files, rapid navigation, two viewer windows, minimum sizing, reduced motion, and VoiceOver controls. Verify opening viewer does not alter file contents.
- [ ] Apply documentation gate; commit viewer and Gallery deliverables separately with `feat(photos): ...` messages.

## Task 8: Full app localization

**Files:** Modify Package.swift, scripts/run.sh bundle resource handling, SharkApp.swift, Services/SharkSettings.swift, SettingsView.swift, and all user-facing text sources. Create Sources/Shark/Resources localization resources for en/ar/es/fr/de/pt-BR/zh-Hans/ja and Tests/SharkTests/LocalizationTests.swift. Use SwiftPM-compatible localized resources; ensure AppKit/menu/bundle locale matches SwiftUI.

**Interface:** Stable localization keys and preference IDs separate from translated display text. System Default is the default; explicit override applies consistently on next launch. Resource packaging must work in both SwiftPM and bundled app runs.

- [ ] Add failing resource/key coverage and preference migration tests; assert old English enum storage values still decode and unknown language preference falls back safely.
- [ ] Run `swift test --filter Localization`; observe failures before resource/infrastructure implementation.
- [ ] Add localization configuration/resource packaging and the System Default/override UI. Extract UI/menu/error/Help/onboarding strings, pluralize counts and use locale-aware display formatting while preserving literal file paths.
- [ ] Translate final text into all eight agreed languages, with English fallback. Keep paths, shortcuts, executable names, and storage keys unmodified.
- [ ] Run coverage tests and full suite. Inspect all settings/help/onboarding and key dialogs across languages; check Arabic RTL, mixed filenames/paths, long German text, and CJK fonts. Verify native text selection and path editing remain usable.
- [ ] Apply documentation gate; commit infrastructure and complete translations as separately reviewable `feat(localization): ...` changes.

## Documentation gate (part of every task)

- [ ] Update CHANGELOG.md under Added/Changed/Fixed with implemented behavior only.
- [ ] Update website/src/data/features.ts; keep selected home-page highlights accurate. Update MouseHelp.zones in Sources/Shark/Views/Help/HelpView.swift whenever mouse behavior changes.
- [ ] Update DESIGN.md for changed interaction/measurement rules, including terminal lifetime/focus, preview fitting, toolbar grouping and viewer controls.
- [ ] Run `npm run build` in website/ and inspect /shark/features/ at desktop/mobile sizes after catalog changes.
- [ ] Keep documentation in the same commit as the owning implementation.

## Final acceptance and handoff

- [ ] Run swift build, swift test, and website npm run build after the last integrated changes.
- [ ] Recheck list double-click and updater behavior with UpdateCheckerTests and safe UI checks; do not install an update merely to test the prompt.
- [ ] Walk the six Notion screenshot scenarios and record expected vs actual outcomes; no screenshot alone proves terminal keys, transactional moves, or frame pacing.
- [ ] Verify macOS 14 availability gates and report any runtime/version/hardware checks that could not be performed.
- [ ] Present delivered items, evidence, remaining limitations, and one conventional commit per independently shipped feature/fix. Publishing, release version assignment, and Notion status writes are separate from this planning scope.
