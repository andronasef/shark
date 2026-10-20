# Phase 7: Pro Tab Strip & Session Restore - Research

**Researched:** 2026-10-20
**Domain:** SwiftUI + AppKit on macOS 14+ (Swift 6 strict concurrency): custom tab strip, menu Commands, drag and drop, middle-click, Codable session persistence
**Confidence:** HIGH for the risky APIs. Each one was checked with throwaway Swift 6 probe apps built against the real SDK (Xcode 27, `-target arm64-apple-macosx14.0`) and driven with System Events and CGEvent on this Mac (macOS 26.6). Nothing was run on a macOS 14 machine.

## Summary

Phase 7 needs **no new dependencies**. All of it is SwiftUI, AppKit and Foundation, which the project already uses. The work splits into three parts:

1. **The model.** Extend `WorkspaceState` and `WorkspaceTab` with pin, lock, colour, closed-tab history, reorder and "open in new tab" routing. Keep all logic in the `@Observable @MainActor` state classes so XCTest can cover it.
2. **The view.** Replace `TabBarView` with a new `TabStripView`/`TabItemView` that follows 07-UI-SPEC.md.
3. **Persistence and menus.** Add a `SessionStore` that writes a Codable `WorkspaceSnapshot`. Move `WorkspaceState` ownership out of `ContentView` to app level, so real menu `Commands` and the terminate-time save can reach it.

The probes settled every high-risk question:
- `Commands` **do** re-render when an `@Observable` object they read changes: the menu title flipped from Pin Tab to Unpin Tab, and the enabled state updated.
- `CommandGroup(replacing: .saveItem)` takes over ⌘W.
- ⌃Tab, ⌃⇧Tab, ⌥⌘1, ⇧⌘] and ⇧⌘T all dispatch through menu items, even while a TextField is present.
- A local `NSEvent` monitor combined with per-view `onHover` **does** receive middle-clicks. The `NSViewRepresentable` hitTest overlay named in UI-SPEC **did not** receive them on macOS 26.6.
- Both `.draggable`/`.dropDestination` and `.onDrag`/`DropDelegate` complete in-app drops.
- `applicationWillTerminate` runs on ⌘Q but **not** on `pkill`/`killall`, which are what `scripts/run.sh` and `scripts/hot_reload.py` use.

The probes also found existing bugs this phase must fix:
- ⇧⌘T is already bound to the terminal toggle (`ContentView.swift:357`).
- `CommandMenu("View")` in `SharkApp` creates a **second** View menu.
- Native window tabbing adds "Show Tab Bar" and "Show All Tabs" to View.
- Duplicate Tab and ⌘T at the same URL will show an empty folder, because `DirectoryView` keeps its identity and `.task(id: currentURL)` does not re-fire.

**Primary recommendation:**
- Ownership: `@MainActor AppDelegate` owns `WorkspaceState` (restored synchronously from `SessionStore` in its stored-property initialiser) and `SessionStore`. `SharkApp` passes `appDelegate.workspace` to `ContentView` and to a `TabCommands: Commands` struct.
- Saving: `SessionStore` observes the graph with re-armed `withObservationTracking`, debounces 0.5s, writes atomically, and saves synchronously in `applicationWillTerminate`.
- Middle-click: hover registry plus one local monitor.
- Reorder: `.onDrag` plus `DropDelegate`.

## Architectural Responsibility Map

The tiers here are the native-app equivalents of the usual web tiers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tab list, ordering, pin/lock/colour, closed history, open-in-new-tab routing | State (`WorkspaceState`, `WorkspaceTab`) | — | Pure logic on `@Observable @MainActor` classes, unit-testable without UI |
| Tab strip rendering, hover, drag/drop, context menu, tooltip | SwiftUI View (`TabStripView`, `TabItemView`) | — | Presentation only; every mutation calls a `WorkspaceState` method |
| Middle-click detection | AppKit bridge (one `NSEvent` local monitor) | SwiftUI `onHover` | SwiftUI has no middle-button gesture; see Pattern 3 |
| Menu bar Tab menu and shortcuts | App scene (`Commands`) | Hidden `keyboardShortcut` buttons for the secondary ⇧⌘[ and ⇧⌘] | A menu item carries only one key equivalent |
| Session snapshot, load, save, debounce | Persistence (`SessionStore` + `WorkspaceSnapshot`) | `AppDelegate` (terminate hook) | File I/O and Codable, testable with an injected file URL |
| Lock and ⌘/middle-click "open in new tab" from panes, sidebar and breadcrumb | State (`WorkspaceState.open(_:from:newTab:)`) | Views pass the modifier state | One routing function; views only detect the gesture |

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Tab strip appearance (Finder/Safari)
- Strip is always visible, even with one tab (QTTabBar behaviour); height 28pt, sits directly under the unified toolbar across the detail column, background = toolbar/titlebar material (`.bar` / windowBackground darker in dark mode).
- Tabs are equal width and fill the strip (min 120pt, max 260pt; overflow scrolls horizontally with the active tab kept visible). Title centred, 11–12pt system font, truncation middle.
- Active tab uses the content background with a subtle top/side separator; inactive tabs are recessed with 0.5pt hairline separators between them, exactly like Finder tabs.
- Close "x" appears on hover at the leading edge (Finder style); for the active tab it is always visible on hover only. Leading folder icon 14pt from NSWorkspace for the active pane path.
- Colour: optional tint shown as an 8pt dot before the title (system colours: red, orange, yellow, green, blue, purple, gray, matching Finder tag colours). No other custom colour.
- Pinned tabs: compact 40pt icon-only tabs at the far left, no close button, tooltip shows title/path. Locked tabs: show a small `lock.fill` glyph after the title.
- "+" button at the trailing edge of the strip.
- Tooltip on every tab: full path of the active pane (both paths when split).

### Tab interactions
- Drag to reorder using SwiftUI `.onDrag`/`.onDrop` (or `draggable`/`dropDestination` with tab UUID string); pinned tabs stay in the pinned group and unpinned in theirs.
- Middle-click closes a tab: implement with an `NSViewRepresentable` overlay or local `NSEvent` monitor for `.otherMouseUp` (buttonNumber 2) hit-testing the tab frame.
- Double-click on empty strip area opens a new tab at the active path.
- Context menu on a tab: New Tab, Duplicate Tab, Pin/Unpin Tab, Lock/Unlock Tab, Colour ▸ (None + 7 colours), Copy Path, Close Tab, Close Other Tabs, Close Tabs to the Right, Reopen Closed Tab.
- Close Others keeps pinned tabs. Closing the last tab keeps the window open with one tab at Home (existing behaviour).
- Locked tab: activating (double-click/Return) a folder opens it in a new tab next to the locked one instead of navigating; back/forward is still allowed.
- ⌘-double-click (or ⌘-Return) on a folder opens it in a new background tab inserted after the current tab; middle-click on a folder or sidebar item does the same.

### Keyboard
- ⌘T new tab (at current path), ⌘W close tab, ⇧⌘T reopen closed tab, ⌃Tab / ⌃⇧Tab and ⇧⌘] / ⇧⌘[ next/previous tab, ⌥⌘1–9 select tab N (9 = last). ⌘1–4 remain Finder view modes.
- All tab commands also appear in a "Tab" area of the menu bar (the full menu bar is Phase 10, but these commands must be real `Commands`, not hidden zero-opacity buttons).

### Persistence & closed-tab history
- `SessionStore` writes a Codable `WorkspaceSnapshot` (tabs: id, pinned, locked, colour, isSplit, activePane, per-pane url + viewMode + sortField + sortAscending + showHidden + iconSize; activeTabID; closedTabs) to `~/Library/Application Support/Shark/session.json`.
- Save debounced (~0.5s) on any change and synchronously on `applicationWillTerminate`; restore on launch. Paths that no longer exist fall back to the nearest existing ancestor, then Home. Corrupt file → start fresh, never crash.
- Closed-tab history keeps the last 20 closed tabs (full snapshot incl. back/forward not required — path, view, split are enough); persisted with the session. "Reopen Closed Tab" restores at original index when possible.

### Claude's Discretion
- Exact file split (e.g. `TabStripView.swift`, `TabItemView.swift`, `SessionStore.swift`, `WorkspaceSnapshot.swift`) and whether middle-click uses an overlay or event monitor.
- Animation: tab insert/remove/reorder use a short (≤200ms) default spring; respect Reduce Motion.

### Deferred Ideas (OUT OF SCOPE)
- Tab groups (saved sets) → Phase 9 (QT-05).
- Setting to hide the strip with one tab → Phase 10 Settings (CMD-04).
- Dragging a tab out to a new window / between windows → later milestone.
</user_constraints>

**UI contract:** 07-UI-SPEC.md (approved) is binding for visuals, copy, menu order, accessibility labels and motion. This research does not restate it. Where research contradicts a UI-SPEC *implementation* note (the middle-click overlay), the visible behaviour is unchanged and the mechanism falls under CONTEXT's "Claude's Discretion".

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TAB-01 | Full-width strip always visible, equal-width tabs, hover close, path tooltip | Pattern 2 (strip layout), `.help`, `NSWorkspace.icon`; UI-SPEC layout tables |
| TAB-02 | Drag reorder; middle-click close; double-click empty strip → new tab | Pattern 3 (middle-click, probe-verified), Pattern 4 (onDrag + DropDelegate, probe-verified), Pitfall 6 |
| TAB-03 | ⇧⌘T reopen from last-20 history + "Recently Closed" menu | Pattern 1 (Commands observe @Observable, probe-verified), conditional submenu (Pitfall 3), ⇧⌘T conflict (Pitfall 1) |
| TAB-04 | Context menu: Duplicate, Pin, Lock, Close Others, Close Right, Colour, Copy Path | Model API table; Pitfall 5 (Duplicate shows empty folder) |
| TAB-05 | Pinned compact at left, survive Close Others | Single-array invariant "pinned prefix" (Pattern 5) |
| TAB-06 | Session restore of tabs, pins, locks, colours, paths, split, view mode | Pattern 6 (SessionStore), Pattern 7 (restore before first frame), Pitfalls 2, 7, 8 |
| TAB-07 | ⌘-double-click / ⌘-click sidebar or breadcrumb / middle-click → new background tab; ⌥⌘1–9; ⌃Tab cycle | `NSEvent.modifierFlags` at activation; `WorkspaceState.open(_:from:newTab:)`; shortcuts probe-verified |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- There is no project `CLAUDE.md`. `.planning/config.json` sets `claude_md_path: ./.agents/GEMINI.md`, but that file does not exist `[VERIFIED: ls]`. There are no project skills (`.claude/skills` and `.agents/skills` are absent).
- From the user's global CLAUDE.md: **update `CHANGELOG.md`** for meaningful changes (Keep a Changelog format; the file exists with an `[Unreleased]` section).
- From STATE.md and PRODUCT.md:
  - Build and run with `scripts/run.sh`; test with `swift test`.
  - Verify by driving the running app with cua-driver and taking a screenshot before declaring UI done.
  - Use pure Swift/SwiftUI/AppKit and never block the main thread.
  - Follow the Finder look; use system colours only.
  - Respect VoiceOver, Reduce Motion and Increase Contrast.
- Established patterns `[VERIFIED: code read]`: `@Observable @MainActor public final class`; `@Bindable` in views; `@ObserveInjection var inject` + `.enableInjection()` on main views; XCTest classes marked `@MainActor`.
- Deployment target is `.macOS(.v14)` `[VERIFIED: Package.swift:6-8]`, but the SDK is Xcode 27. **Do not use macOS 15+ APIs** without `#available`: no `onModifierKeysChanged`, `windowDismissBehavior`, `Observations`, or the WWDC26 reordering API.

## Standard Stack

### Core (all already linked; nothing to add)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | macOS 14 SDK surface (built with Xcode 27 / Swift 6.4) | Strip, Commands, drag/drop, context menus | Already the UI layer `[VERIFIED: swift --version → Apple Swift 6.4]` |
| AppKit | system | `NSEvent` local monitor, `NSWorkspace.icon`, `NSPasteboard`, `NSApplicationDelegate` | Already used for bridges |
| Foundation `JSONEncoder`/`JSONDecoder` | system | Session file | Codable; no persistence framework needed |
| Observation | system (macOS 14) | `withObservationTracking` for debounced autosave | The only macOS 14 way to observe an `@Observable` graph outside a view |
| os `Logger` | system | "Session restore failed" log (UI-SPEC copy) | Native, privacy-aware |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Inject | from 1.2.4 (existing) | `@ObserveInjection` on new views | Follow the existing pattern only |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.onDrag` + `DropDelegate` | `.draggable(String)` + `.dropDestination(for: String.self)` | Both verified working. `draggable` has no drag-start callback, so the UI-SPEC's "source at 0.4 opacity" cannot be known until drop. `dropDestination` also has no live location for the insertion bar. Use DropDelegate. |
| Hover registry + local `NSEvent` monitor | `NSViewRepresentable` overlay with `hitTest` gating | The overlay **failed** in the probe on macOS 26.6. Apple forums also report macOS 26 hit-testing regressions for layered hosting views. |
| App-owned single `WorkspaceState` | Per-window state + `@FocusedValue`/`focusedSceneValue` | The snapshot schema is single-workspace and drag-out-to-new-window is deferred, so per-window state adds plumbing and buys nothing now |
| `WindowGroup` + `CommandGroup(replacing: .newItem) {}` | `Window("Shark", id: "main")` | `Window` makes the app **quit when the window closes** `[CITED: developer.apple.com/documentation/swiftui/window]`, which is not Finder-like. Keep `WindowGroup` and remove New Window so the shared state never shows up in two windows. |
| JSON file | `UserDefaults` / `@AppStorage` / SwiftData | The CONTEXT locks `session.json`. A JSON file is inspectable and easy to delete in tests. |

**Installation:** none.

## Package Legitimacy Audit

No external packages are installed by this phase. `Package.swift` is unchanged.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 launch ──► AppDelegate.init (stored-property init, @MainActor)
             │  SessionStore.load(fileURL) ──► session.json ──decode──► WorkspaceSnapshot
             │        │ corrupt/missing → nil → WorkspaceState(initialURL: nil)   (log, no dialog)
             │        ▼ resolve paths (nearest existing ancestor → Home)
             └─► workspace: WorkspaceState  (single source of truth)
                     │
   SharkApp.body ────┼──► WindowGroup { ContentView(workspace) }   ← first frame already restored
                     │        ├─ TabStripView ── tap/drag/hover/context menu ──► workspace.<op>()
                     │        ├─ DirectoryView/Sidebar/Breadcrumb ── activate(+⌘ / middle / locked) ──► workspace.open(url, from:pane, newTab:)
                     │        └─ hidden buttons ⇧⌘[ ⇧⌘] ──► workspace.previousTab()/nextTab()
                     └──► .commands { TabCommands(workspace) }  (Tab menu, ⌘W via .saveItem) ──► workspace.<op>()

   NSEvent local monitor (.otherMouseUp, button 2) ──► MiddleClick.target (set by onHover) ──► closure

   workspace mutations ──► withObservationTracking(onChange) ──► SessionStore debounce 0.5s ──► atomic write session.json
   ⌘Q ──► applicationWillTerminate ──► SessionStore.saveNow()   (NOT reached on pkill/killall)
```

### Recommended Project Structure
```
Sources/Shark/
├── SharkApp.swift                 # AppDelegate owns workspace + store; TabCommands; allowsAutomaticWindowTabbing=false
├── State/
│   ├── WorkspaceState.swift       # + pin/lock/colour/move/duplicate/closeOthers/closeRight/reopen/selectIndex/open(_:from:newTab:)
│   ├── WorkspaceTab.swift         # + isPinned, isLocked, color: TabColor?
│   ├── WorkspaceSnapshot.swift    # Codable value types + TabColor + snapshot()/init(snapshot:) mapping
│   └── SessionStore.swift         # load/save/debounce/observe; injected fileURL
├── Views/Workspace/
│   ├── TabStripView.swift         # replaces TabBarView.swift (delete it)
│   ├── TabItemView.swift
│   └── MiddleClick.swift          # monitor + .onMiddleClick modifier (reused by panes/sidebar/breadcrumb)
Tests/SharkTests/
├── WorkspaceStateTests.swift      # extend
└── SessionStoreTests.swift        # new
```
`TabCommands` can live in `SharkApp.swift`, which is already the commands file. Fewest files wins.

### Pattern 1: App-owned state + real Commands (probe-verified)
**What:** `AppDelegate` owns the workspace. `SharkApp` reads it through the adaptor and hands it to both the scene and the commands.
**Why AppDelegate:** it already exists, the terminate hook lives there, and `@NSApplicationDelegateAdaptor` instantiates it before `body`. No singleton is needed.

```swift
// Probe-verified: compiles with -swift-version 6 at macOS 14 target; menu titles/enabled update live.
@MainActor   // REQUIRED: without it → "main actor-isolated default value in a nonisolated context" (probe error)
final class AppDelegate: NSObject, NSApplicationDelegate {
    let session = SessionStore()                       // default fileURL = Application Support/Shark/session.json
    lazy var workspace: WorkspaceState = session.restore() ?? WorkspaceState()

    func applicationWillFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSWindow.allowsAutomaticWindowTabbing = false  // removes View ▸ Show Tab Bar / Show All Tabs (probe-verified)
    }
    func applicationWillTerminate(_ n: Notification) { session.saveNow(workspace) }  // runs on ⌘Q only
}

struct TabCommands: Commands {
    let workspace: WorkspaceState
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}           // no New Window: one window shares one state
        CommandGroup(replacing: .saveItem) {           // owns ⌘W (default "Close" removed, probe-verified)
            Button("Close Tab") { workspace.closeTab(id: workspace.activeTabID) }.keyboardShortcut("w")
        }
        CommandMenu("Tab") {                           // appears after View (probe-verified order)
            Button("New Tab") { workspace.newTab() }.keyboardShortcut("t")
            Button("Reopen Closed Tab") { workspace.reopenClosedTab() }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                .disabled(workspace.closedTabs.isEmpty)
            if workspace.closedTabs.isEmpty {          // .disabled on a Menu does NOT disable it (probe) → branch
                Button("Recently Closed") {}.disabled(true)
            } else {
                Menu("Recently Closed") { /* ForEach closedTabs → reopenClosedTab(at:) */ }
            }
            Divider()
            Button("Show Next Tab") { workspace.nextTab() }.keyboardShortcut(.tab, modifiers: .control)
            Button("Show Previous Tab") { workspace.previousTab() }.keyboardShortcut(.tab, modifiers: [.control, .shift])
            // ForEach 1...8: keyboardShortcut(KeyEquivalent(Character("\(n)")), modifiers: [.command, .option]); 9 = last
            Divider()
            Button(workspace.activeTab.isPinned ? "Unpin Tab" : "Pin Tab") { workspace.togglePin(id: workspace.activeTabID) }
            // Duplicate, Lock/Unlock, Copy Path per UI-SPEC order
        }
    }
}
```
In `SharkApp`, use `WindowGroup { ContentView(workspace: appDelegate.workspace) … }.commands { SidebarCommands(); TabCommands(workspace: appDelegate.workspace) }`. In `ContentView`, replace `@State private var workspaceState = WorkspaceState()` with `let workspaceState: WorkspaceState` (or `@Bindable var`).

Notes:
- `lazy var` sidesteps the init-order problem, and so does a plain `let` in a `@MainActor` class. Both compiled in the probe; `let` with `@MainActor` is what was probe-verified.
- Observation in `Commands` was verified on a **macOS 26.6 runtime**: "Pin Tab" became "Unpin Tab" and Reopen went from disabled to enabled after a state change `[VERIFIED: probe app + System Events]`. On a macOS 14 runtime this is `[ASSUMED]`. If menus ever go stale there, the fallback is to rebuild labels on `menuNeedsUpdate`, which is not needed now.

### Pattern 2: Strip layout
- Wrap the strip in a `GeometryReader`. Compute `unpinnedWidth = min(260, max(120, (w - pinnedCount*40 - 28) / max(1, unpinnedCount)))` per UI-SPEC.
- Layout: `HStack(spacing: 0) { pinned ForEach (fixed) ; ScrollViewReader { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 0) { unpinned ForEach } } } ; emptyArea ; plusButton }`.
- Keep the active tab visible with `.onChange(of: workspace.activeTabID) { proxy.scrollTo(id) }` plus `.onAppear`, which covers restore.
- Empty area: `Color.clear.contentShape(Rectangle()).onTapGesture(count: 2) { workspace.newTab(at: .end) }`. Do **not** put a double-tap on tabs: SwiftUI delays single taps that share a view with a double-tap.
- Read `@Environment(\.accessibilityReduceMotion)`; animate with `.spring(duration: 0.2, bounce: 0)`, or with an opacity crossfade when Reduce Motion is on.
- Read `@Environment(\.colorSchemeContrast)` for the Increase Contrast overlay values (UI-SPEC).

### Pattern 3: Middle-click = hover registry + one local monitor (probe-verified)
```swift
// Verified on macOS 26.6: approach fired on synthesized button-2 clicks; NSViewRepresentable hitTest overlay did NOT.
@MainActor enum MiddleClick {
    static var target: (id: UUID, action: () -> Void)?
    static func install() {                       // call once in applicationDidFinishLaunching
        _ = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { e in
            guard e.buttonNumber == 2, let t = MiddleClick.target else { return e }
            t.action(); return nil                // consume
        }
    }
}
struct MiddleClickModifier: ViewModifier {
    let action: () -> Void
    @State private var id = UUID()
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside { MiddleClick.target = (id, action) }
            else if MiddleClick.target?.id == id { MiddleClick.target = nil }   // enter/exit can interleave
        }
    }
}
extension View { func onMiddleClick(_ action: @escaping () -> Void) -> some View { modifier(MiddleClickModifier(action: action)) } }
```
- The same modifier serves the tabs (close), folder items in the grid, list and compact views, sidebar rows and breadcrumb popover rows (open in background tab, TAB-07).
- The local monitor sees events for every window in the app, popovers included.
- The tab strip may already have `onHover` for the close glyph. Chain both modifiers; SwiftUI allows several `onHover` modifiers on one view.

### Pattern 4: Reorder with `.onDrag` + `DropDelegate` (probe-verified)
```swift
// .onDrag gives a drag-start hook (set draggingID → source 0.4 opacity); DropDelegate gives location → insertion bar side.
TabItemView(...)
    .onDrag { draggingID = tab.id; return NSItemProvider(object: tab.id.uuidString as NSString) }
    .onDrop(of: [.text], delegate: TabDropDelegate(target: tab, workspace: workspace, draggingID: $draggingID, indicator: $indicator))

struct TabDropDelegate: DropDelegate {          // DropDelegate methods compile as MainActor under Swift 6 (probe)
    func dropUpdated(info: DropInfo) -> DropProposal? { /* indicator = info.location.x < width/2 ? .before : .after */ return DropProposal(operation: .move) }
    func dropExited(info: DropInfo) { indicator = nil }
    func performDrop(info: DropInfo) -> Bool { /* workspace.moveTab(id: draggingID, to: index); draggingID = nil */ return true }
}
```
- Use the `draggingID` captured at drag start for the move. Do not decode the item provider: that is async, and a local ID is already known.
- `moveTab(id:to:)` in `WorkspaceState` **clamps** the destination into the dragged tab's own group (pinned prefix or unpinned suffix).
- Clear `draggingID` in `performDrop`. Also clear it on the strip-level `dropExited` and when a new drag starts (Pitfall 6).

### Pattern 5: Single `tabs` array with a pinned-prefix invariant
Keep one `tabs: [WorkspaceTab]`; all pinned tabs come before all unpinned ones. Visual order equals array order, so ⌥⌘N indexes the array directly (UI-SPEC: "pinned first, in visual order").

| Operation | Rule |
|-----------|------|
| `newTab(url:, placement: .afterActive / .end, select:)` | The insertion index is clamped to ≥ `pinnedCount`, so a new tab is never inside the pinned group |
| `togglePin` | Pin moves the tab to `pinnedCount` (end of the pinned group). Unpin moves it to the start of the unpinned group. |
| `duplicateTab(id)` | Insert after the source; copy panes, split, view settings, colour and pin; **not** lock; select the copy |
| `closeTab(id)` | Push a `ClosedTab(snapshot, index)` onto `closedTabs` (insert at 0, cap 20). If it was the last tab, replace it with a fresh unpinned Home tab. |
| `closeOtherTabs(id)` / `closeTabsToRight(id)` | Skip pinned **and** locked tabs (UI-SPEC); push each closed tab to history |
| `reopenClosedTab(at: 0)` | Rebuild from the snapshot, insert at `min(index, count)` (clamped to the group), select |
| `selectTab(number:)` | 1–8 select by index if it exists; 9 selects the last |
| `open(_ url:, from pane: NavigationState, newTab: Bool)` | Find the owning tab with `tabs.first { $0.primaryPane === pane \|\| $0.secondaryPane === pane }`. `newTab` (⌘/middle) opens a background tab after the current one. A **locked** owner opens a foreground tab after the locked one. Otherwise `pane.navigateTo(url)`. |

Views call `open` and pass `newTab: NSEvent.modifierFlags.contains(.command)`. `NSEvent.modifierFlags` is the class property for the current modifier state; it compiled in the probe and is available on macOS 10.6+.

### Pattern 6: SessionStore (observation + debounce + atomic write)
```swift
// Probe-verified to compile under Swift 6 at macOS 14 target.
@MainActor final class SessionStore {
    let fileURL: URL
    private var saveTask: Task<Void, Never>?
    init(fileURL: URL = URL.applicationSupportDirectory.appending(path: "Shark/session.json")) { self.fileURL = fileURL }

    func restore() -> WorkspaceState? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }            // missing → fresh
        do { return WorkspaceState(snapshot: try JSONDecoder().decode(WorkspaceSnapshot.self, from: data)) }
        catch { logger.error("Session restore failed: \(error); starting fresh"); return nil }  // UI-SPEC copy
    }
    func startAutosave(_ ws: WorkspaceState) {                    // call once after restore
        withObservationTracking { _ = ws.snapshot() }             // reads every persisted property
        onChange: { [weak self] in Task { @MainActor in self?.changed(ws) } }   // fires on willSet, once → re-arm
    }
    private func changed(_ ws: WorkspaceState) {
        startAutosave(ws)
        saveTask?.cancel()
        saveTask = Task { try? await Task.sleep(for: .milliseconds(500)); guard !Task.isCancelled else { return }; saveNow(ws) }
    }
    func saveNow(_ ws: WorkspaceState) {
        saveTask?.cancel()
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(ws.snapshot()).write(to: fileURL, options: .atomic)
        } catch { logger.error("Session save failed: \(error)") }
    }
}
```
- `withObservationTracking`'s `onChange` fires on **willSet**, once only. The `Task { @MainActor }` hop runs after the mutation completes, re-arms tracking, then debounces. (`URL.applicationSupportDirectory`, `.appending(path:)` and `Task.sleep(for:)` are all macOS 13+.)
- Writing a few KB of JSON on the main actor costs well under a millisecond. Do not move it off the main thread (YAGNI).

### Pattern 7: Snapshot types and restore before the first frame
In-repo values, quoted verbatim:
- `public enum PaneIdentifier: String, CaseIterable, Sendable { case primary; case secondary }` `[VERIFIED: Sources/Shark/State/WorkspaceTab.swift:4-7]`
- `public enum SortField: String, CaseIterable, Identifiable, Sendable { case name = "Name"; case dateModified = "Date Modified"; case size = "Size"; case kind = "Kind"; case permissions = "Permissions" }` `[VERIFIED: Sources/Shark/State/NavigationState.swift:4-12]`
- `public enum ViewMode: String, CaseIterable, Identifiable, Sendable { case grid = "Icons"; case details = "List"; case compact = "Columns"; case gallery = "Gallery" }` `[VERIFIED: Sources/Shark/State/NavigationState.swift:14-30]`
- NavigationState persisted fields: `public var currentURL: URL`, `public var showHiddenFiles: Bool = false { didSet { Task { await reloadCurrentDirectory() } } }`, `public var viewMode: ViewMode = .grid`, `public var iconSize: CGFloat = 80.0`, `public var sortField: SortField = .name`, `public var sortAscending: Bool = true` `[VERIFIED: Sources/Shark/State/NavigationState.swift:35-60]`
- WorkspaceTab: `public let id: UUID`, `public var isSplit: Bool`, `public var activePane: PaneIdentifier`, `public let primaryPane: NavigationState`, `public let secondaryPane: NavigationState`, `init(id: UUID = UUID(), initialURL: URL? = nil, isSplit: Bool = false)` `[VERIFIED: Sources/Shark/State/WorkspaceTab.swift:11-28]`

```swift
public enum TabColor: String, Codable, CaseIterable, Sendable { case red, orange, yellow, green, blue, purple, gray }

public struct PaneSnapshot: Codable, Equatable, Sendable {
    var url: URL; var viewMode: String; var sortField: String   // case NAMES, not display rawValues (Pitfall 8)
    var sortAscending: Bool; var showHidden: Bool; var iconSize: CGFloat
}
public struct TabSnapshot: Codable, Equatable, Sendable {
    var id: UUID; var isPinned: Bool; var isLocked: Bool; var color: TabColor?
    var isSplit: Bool; var activePane: PaneIdentifier; var primary: PaneSnapshot; var secondary: PaneSnapshot
}
public struct ClosedTab: Codable, Equatable, Sendable { var tab: TabSnapshot; var index: Int }
public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    var tabs: [TabSnapshot]; var activeTabID: UUID?; var closedTabs: [ClosedTab]
}
// decode a case name: ViewMode.allCases.first { "\($0)" == s } ?? .grid
```
- `PaneIdentifier` needs `Codable` added, which is one word. Since `WorkspaceTab` is `public`, `TabColor` and any type used in a public property must also be `public` (compile error otherwise).
- **Restore before the first frame:** the restore runs inside `AppDelegate`'s stored-property initialiser, before `SharkApp.body` builds the `WindowGroup`. The first `ContentView` therefore already sees restored tabs, and there is no Home-tab flash.
- `init(snapshot:)` must:
  - drop an empty `tabs` array (use a fresh Home tab instead);
  - re-establish the pinned-prefix invariant, using a stable partition;
  - fall back to the first tab if `activeTabID` is missing;
  - cap `closedTabs` at 20.

Path fallback, applied per pane on restore:
```swift
func existingAncestor(_ url: URL) -> URL {
    var u = url.standardizedFileURL; var isDir: ObjCBool = false
    while u.path != "/" { if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue { return u }; u.deleteLastPathComponent() }
    return FileManager.default.homeDirectoryForCurrentUser
}
```
Note that an unmounted `/Volumes/X/a` resolves to `/Volumes`, which exists. That is literally "nearest existing ancestor" per CONTEXT. It is acceptable; mention it in the plan.

### Anti-Patterns to Avoid
- **`CommandMenu("View")` for View-menu items.** It creates a **duplicate** View menu (probe menu bar: `File, Edit, View, View, Tab, Window`). Use `CommandGroup(after: .toolbar)` to add to the system View menu.
- **Menu items with empty actions.** `SharkApp.swift:34-44` has "Toggle Split View" ⌥⌘S and "Show/Hide Hidden Files" ⇧⌘. with `// Handled in ContentView` bodies. Menu key equivalents win, so those shortcuts are dead. Now that state is app-owned, wire them for real (`workspace.toggleSplit()`, `workspace.activeNavigationState.showHiddenFiles.toggle()`) inside `CommandGroup(after: .toolbar)`.
- **A tab-strip keyboard path through hidden zero-opacity buttons** for anything except the secondary ⇧⌘[ and ⇧⌘] (CONTEXT requires real Commands).
- **Two arrays for pinned and unpinned tabs.** Index math for ⌥⌘N, reopen-at-index and drag doubles. Use one array with the prefix invariant.
- **The `activeTab` getter that mutates state.** `WorkspaceState.swift:16-26` appends a fallback tab inside a getter, which is called during view updates. Keep the "tabs is never empty" invariant in every mutating op (close, restore) so the fallback never runs.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic file write | temp file + rename | `Data.write(to:options: .atomic)` | Same guarantee, one call |
| Change detection over the model graph | manual `didSet` on every property that calls `markDirty()` | `withObservationTracking` on `snapshot()` | Automatically covers any field later added to `snapshot()` |
| Debounce | a timer class or Combine pipeline | cancel and recreate a `Task` with `Task.sleep` | 4 lines, structured concurrency |
| Tooltips | custom popover on hover | `.help(String)` | System delay and styling |
| Context menu and Colour submenu | custom popup | `.contextMenu { Menu("Colour") { … } }` | Native NSMenu rendering; UI-SPEC expects it |
| Menu enable and label updates | NotificationCenter bridging, `NSMenuDelegate` | `Commands` reading the `@Observable` workspace | Probe-verified live updates |
| Horizontal overflow + keep active visible | manual offset math | `ScrollView(.horizontal)` + `ScrollViewReader.scrollTo` | Built in |
| Tab drag ghost image | custom drag window | the system drag preview from `.onDrag` | UI-SPEC: "System drag preview" |
| F4 key binding | an NSEvent keyCode monitor | `KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!))` in a menu item | Probe-verified to fire |

**Key insight:** every risky interaction (menus, shortcuts, middle-click, drag) has a 3–15 line native path that was verified in this session. Nothing here justifies a dependency or an AppKit subclass of the strip.

## Common Pitfalls

### Pitfall 1: ⇧⌘T is already taken by the terminal
**What goes wrong:** `ContentView.swift:357` binds ⇧⌘T to `toggleTerminalDrawer()` through a hidden button `[VERIFIED: code read]`. Adding ⇧⌘T for Reopen Closed Tab means two bindings fight; the menu wins, but the terminal shortcut silently disappears.
**How to avoid:** delete that hidden button. Bind the terminal to **F4**, which is what TERM-01 always specified, as a View-menu item: `Button("Toggle Terminal") { … }.keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!)), modifiers: [])` in `CommandGroup(after: .toolbar)`. Probe-verified to fire on key code 118. On a physical Mac keyboard the user may need fn+F4, depending on their system setting. Terminal visibility is `@State` in `ContentView`, so the menu item needs that state lifted onto `WorkspaceState`, or a `@FocusedBinding`. Lifting it as `var isTerminalVisible` on `WorkspaceState` is the lazy route; it is *not* persisted.
**Warning signs:** ⇧⌘T toggles the terminal, or does nothing.

### Pitfall 2: `applicationWillTerminate` does not run on `pkill`/`killall`
**What goes wrong:** the probe confirmed that ⌘Q calls `applicationWillTerminate` and SIGTERM (`pkill -x`) does not. `scripts/run.sh` uses `pkill -x Shark` and `scripts/hot_reload.py` uses `killall Shark` `[VERIFIED: code read]`.
**How to avoid:** rely on the 0.5s debounced save as the real safety net. In GUI verification of TAB-06, quit with **⌘Q** (cua-driver hotkey or the menu) and wait about 1s before `pkill` or relaunch. Never verify restore via `run.sh` alone right after a change.
**Warning signs:** restore "loses" the last change only in dev loops.

### Pitfall 3: `.disabled()` on a `Menu` inside Commands does nothing
**What goes wrong:** in the probe, `Menu("Recently Closed") {…}.disabled(true)` stayed enabled.
**How to avoid:** branch with `if closedTabs.isEmpty { Button("Recently Closed"){}.disabled(true) } else { Menu(…) }`. This was probe-verified: the disabled item became a populated submenu after a state change.

### Pitfall 4: ⌘W is owned by File ▸ Close
**What goes wrong:** a Tab-menu ⌘W loses to the default File ▸ Close.
**How to avoid:** `CommandGroup(replacing: .saveItem)` ("commands that save open documents and close windows" `[CITED: developer.apple.com/documentation/swiftui/commandgroupplacement]`). The probe confirmed File then held only "Close Tab" and ⌘W dispatched to it. If the planner wants Finder's ⇧⌘W Close Window, add it in the same group with `NSApp.keyWindow?.performClose(nil)`.
**Side effect:** ⌘W no longer closes other windows the app may show, such as the About panel. That is acceptable for now; Phase 10 owns the full menu bar.

### Pitfall 5: Duplicate Tab and ⌘T at the same URL show "Folder is Empty"
**What goes wrong:** `ContentView` renders `DualPaneContainerView(tab: workspaceState.activeTab)` at a fixed structural position, so switching tabs keeps the same `DirectoryView` identity. `DirectoryView` loads with `.task(id: navigationState.currentURL)` `[VERIFIED: DirectoryView.swift:28-31]`. A new tab whose URL equals the previous tab's URL has an empty `items` array, and the task never re-fires. The new tab shows the empty state until something else reloads it. This already affects today's `newTab()` (same URL by default), and Duplicate makes it routine. `[ASSUMED: reasoned from code; verify in GUI]`
**How to avoid:** add one line in `ContentView`: `DualPaneContainerView(tab: workspaceState.activeTab).id(workspaceState.activeTabID)`. This also resets the per-view `FSEventsWatcher` per tab.
**Warning signs:** ⌘T or Duplicate shows "Folder is Empty" in a non-empty folder.

### Pitfall 6: A stale `draggingID` after a cancelled drag
**What goes wrong:** `.onDrag` has a start hook but no end hook. If the user presses Esc or drops outside the strip, the source tab stays at 0.4 opacity.
**How to avoid:** dim the source only while `draggingID == tab.id && stripIsTargeted`, where `stripIsTargeted` comes from a strip-level drop delegate's enter/exit. Clear it in `performDrop`, and overwrite it on the next drag start. Verify in GUI.

### Pitfall 7: `showHiddenFiles` has a `didSet` that reloads
**What goes wrong:** setting `showHiddenFiles = true` during restore starts a directory listing for every restored pane, including inactive tabs and hidden secondaries `[VERIFIED: NavigationState.swift:44-48]`.
**How to avoid:** this is acceptable (a few tabs). Optionally set it only when `!=`. Do not add a "restoring" flag (YAGNI).

### Pitfall 8: Persisting display-string rawValues
**What goes wrong:** `ViewMode.compact` has rawValue `"Columns"` and `ViewMode.details` is `"List"`. These are UI labels. Phase 11 (POL-02, a real Columns view) is likely to rename or re-case them. If the snapshot encodes rawValues and one changes, decoding throws and the **whole session is wiped**.
**How to avoid:** persist case names (`"\(mode)"`) and decode leniently with a default (`.grid`, `.name`). An unknown value degrades one field, not the session.

### Pitfall 9: Mac Mouse Fix on this machine eats middle-clicks
**What goes wrong:** `Mac Mouse Fix Helper` and Karabiner-Elements are running `[VERIFIED: ps]`. Synthesized button-2 events posted at `.cghidEventTap` never reached the probe app. The same events posted at `.cgAnnotatedSessionEventTap` did.
**Consequences:**
- (a) The user's **physical** middle button may be remapped by Mac Mouse Fix, which the app cannot see. Tell the user if middle-click "doesn't work".
- (b) If cua-driver's middle-click does not register in GUI verification, the cause is the event tap, not the code. Fall back to the unit test on the action plus a manual check.

### Pitfall 10: Synthesized drags need to dwell before release
**What goes wrong:** a fast synthetic drag (down, moves, up) started the drag session, but the drop was never performed. Holding the cursor at the target for ~0.5s (repeated `leftMouseDragged` at the destination) before mouse-up made both drop APIs fire `[VERIFIED: probe]`.
**How to avoid:** when driving drags with cua-driver, use its drag guide with a dwell at the destination.

### Pitfall 11: Inject is not true hot reload here
**What goes wrong:** `hot_reload.py` rebuilds and `killall`s and relaunches the app `[VERIFIED: scripts/hot_reload.py:46-50]`. Every edit therefore relaunches, restores the session, and bypasses `applicationWillTerminate` (Pitfall 2). A schema change mid-development turns an old `session.json` into a decode failure, which starts fresh by design.
**How to avoid:** for deterministic GUI checks, delete `~/Library/Application Support/Shark/session.json` first. Keep `@ObserveInjection` and `.enableInjection()` on `TabStripView` and `TabItemView` per the UI-SPEC (harmless).

### Pitfall 12: Background tabs open in reverse order
**What goes wrong:** "insert after current" for each ⌘-double-click means opening A, B, C in the background yields `current, C, B, A`.
**How to avoid:** this is acceptable for v1 and matches the CONTEXT wording literally. If wanted, track `lastBackgroundInsertIndex`, reset whenever selection changes. Flagged as an open question; do not build it unless the planner chooses to.

## Code Examples

### ⌘-double-click and lock routing in `DirectoryView.handleActivate`
```swift
// DirectoryView gains: @Environment(WorkspaceState.self) private var workspace
// (ContentView root: .environment(workspaceState) — Observable-in-environment is macOS 14+)
private func handleActivate(_ item: FileItem) {
    if item.isNavigableDirectory {   // [VERIFIED: FileItem.swift: `isDirectory && !isPackage`]
        workspace.open(item.url, from: navigationState, newTab: NSEvent.modifierFlags.contains(.command))
    } else {
        NSWorkspace.shared.open(item.url)
    }
}
// items: .onMiddleClick { if item.isNavigableDirectory { workspace.open(item.url, from: navigationState, newTab: true) } }
```
- The sidebar row `Button` action (`PlacesSidebarView.swift:121-123`) and the breadcrumb popover rows (`ContentView.swift:450-453`) get the same one-line change, plus `.onMiddleClick`.
- `BreadcrumbBarView` is **unused**: no instantiation was found by grep. "Breadcrumb" in TAB-07 therefore means the Path popover rows.
- Both `PlacesSidebarView` and the popover are given `activeState`. Passing `from: activeState` is correct, because the active pane's tab is the active tab.
- `@Environment(WorkspaceState.self)` traps if it is missing. Inject it once at the `ContentView` root. The popover is presented from inside that hierarchy and inherits the environment `[ASSUMED]`; if not, pass the workspace explicitly.

### Copy Path (active pane, UI-SPEC)
```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(tab.activeNavigationState.currentURL.path, forType: .string)   // same API as DirectoryView.swift:375-378
```

### Tooltip text
```swift
var tooltip: String {
    var lines = tab.isSplit ? ["Left: \(tab.primaryPane.currentURL.path)", "Right: \(tab.secondaryPane.currentURL.path)"]
                            : [tab.activeNavigationState.currentURL.path]
    if tab.isPinned { lines.insert(tab.title, at: 0) }
    if tab.isLocked { lines.append("Locked") }
    return lines.joined(separator: "\n")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` in Commands | `@Observable` read directly in a `Commands` body | macOS 14 | Live labels and enabled state without Combine (probe-verified on 26.6) |
| `onChange` from SwiftUI views for autosave | `withObservationTracking` (14+); `Observations` AsyncSequence (macOS 26+) | 2023 / 2025 | Must use `withObservationTracking`; deployment target is 14 |
| `.draggable` / `.dropDestination(for:action:isTargeted:)` | New SwiftUI reordering API (WWDC26, "2027 releases") | 2026 | Unusable at a macOS 14 target. Apple docs list `dropDestination(for:action:isTargeted:)` availability as `macOS 13.0 – 27.2` `[CITED: developer.apple.com/documentation/swiftui/view/dropdestination(for:action:istargeted:)]`, so it is deprecated in the newest SDKs. No warning appears at a macOS 14 target; another reason to prefer `.onDrag` / `DropDelegate`. |

**Deprecated/outdated:** `TabBarView.swift` (replace and delete), the hidden ⇧⌘T terminal button, and `CommandMenu("View")`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Commands re-render on `@Observable` changes on a **macOS 14** runtime (verified only on 26.6) | Pattern 1 | Pin/Lock labels and Reopen enabled state go stale on 14. Low risk: the user runs 26.6. |
| A2 | Pitfall 5 (Duplicate/⌘T empty folder) actually reproduces | Pitfall 5 | None: the `.id(activeTabID)` fix is harmless either way |
| A3 | `.onMiddleClick` (hover) fires inside `Table` cells, `List` sidebar rows and popover rows the same way it did on a plain view | Pattern 3 | Middle-click on folders fails in some views; GUI check per surface |
| A4 | A strip-level drop delegate's exit plus overwrite-on-next-drag is enough to prevent a stuck 0.4 opacity | Pitfall 6 | Cosmetic; GUI check |
| A5 | The breadcrumb popover inherits `.environment(workspaceState)` | Code Examples | Crash on open; pass it explicitly if so (caught on the first GUI click) |
| A6 | Reverse ordering of successive background tabs is acceptable | Pitfall 12 | UX nit |
| A7 | Lock applies to sidebar and breadcrumb navigation as well as double-click (QTTabBar semantics; CONTEXT names only double-click/Return) | Pattern 5 | If the user wants lock to cover double-click only, the routing call in sidebar and breadcrumb becomes a plain `navigateTo`. Low cost either way. |

## Open Questions

1. **⌘-Return to open in a background tab.**
   - What we know: CONTEXT mentions it, but TAB-07 and the success criteria do not. No Return-key activation exists today, and Finder-style Return-to-rename is Phase 8 (EXP-03), with ⌘↓ open in Phase 10.
   - Recommendation: skip ⌘-Return in Phase 7 and note it for Phase 10, where key handling in views is designed.
2. **Last-tab close semantics.**
   - What we know: the current code navigates the sole tab to Home. UI-SPEC says ⌘W on the last pinned tab leaves "one unpinned tab at Home".
   - Recommendation: always push the closing tab to history, then replace it with a fresh Home tab. This is uniform, reversible with ⇧⌘T, and drops pin, lock and colour.
3. **Where terminal visibility lives** once F4 becomes a menu command (Pitfall 1).
   - Recommendation: `var isTerminalVisible` on `WorkspaceState`, not persisted. Same for the inspector only if F11 is touched; it is not required this phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Swift toolchain | build/test | ✓ | Apple Swift 6.4, Xcode 27.0 (27A266a) | — |
| macOS runtime | GUI verification | ✓ | 26.6.2 (25G83) | — |
| `swift test` baseline | regression | ✓ | 28 XCTest, 0 failures (run this session) | — |
| cua-driver | GUI verification | ✓ | running at `~/.local/bin/cua-driver` | System Events via `osascript` (worked for menus and keys this session) |
| Accessibility for event posting | synthetic clicks/keys | ✓ | System Events and CGEvent posting worked | — |
| Mac Mouse Fix / Karabiner | — (interferes) | present | — | Post middle-clicks at the annotated session tap, or verify manually (Pitfall 9) |
| `~/Library/Application Support/Shark/` | session file | absent (created on first save) | — | `createDirectory(withIntermediateDirectories:)` |

**Missing dependencies with no fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (existing; `@MainActor final class …: XCTestCase`) |
| Config file | none; SwiftPM `testTarget` in `Package.swift` |
| Quick run command | `swift test --filter WorkspaceStateTests` and `swift test --filter SessionStoreTests` |
| Full suite command | `swift test` (about 1s today) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TAB-01 | Strip visible with 1 tab, equal widths, hover close, tooltip | GUI (cua-driver screenshot, light and dark; compare with Finder) | manual-driven | n/a |
| TAB-01 | `tooltip` text (single, split, pinned, locked) | unit (if tooltip is a computed property on the tab or a helper) | `swift test --filter WorkspaceStateTests` | ❌ Wave 0 |
| TAB-02 | `moveTab` reorders and clamps to group | unit | `swift test --filter WorkspaceStateTests/testMoveTabClampsToGroup` | ❌ Wave 0 |
| TAB-02 | Drag reorder, middle-click close, double-click empty area | GUI (cua-driver drag with dwell; middle-click, see Pitfall 9) | manual-driven | n/a |
| TAB-03 | `closeTab` pushes history, cap 20 (21 closes → 20), `reopenClosedTab` restores at original index and selects | unit | `swift test --filter WorkspaceStateTests` | ❌ Wave 0 |
| TAB-03 | ⇧⌘T and the Recently Closed submenu populated, disabled when empty | GUI (menu read via cua-driver or System Events) | manual-driven | n/a |
| TAB-04 | duplicate (no lock carried, inserted after), togglePin moves to group edge, toggleLock, setColor, closeOthers/closeRight keep pinned and locked | unit | `swift test --filter WorkspaceStateTests` | ❌ Wave 0 |
| TAB-04 | Context menu items and order exactly as UI-SPEC; Copy Path puts the path on the pasteboard | GUI + unit (pasteboard read in test is OK) | manual + `swift test` | ❌ Wave 0 |
| TAB-05 | Pinned-prefix invariant after pin, unpin, new tab, reopen, restore; Close Others keeps pinned | unit | `swift test --filter WorkspaceStateTests` | ❌ Wave 0 |
| TAB-06 | snapshot → JSON → restore round-trip is `==` (tabs, order, pins, locks, colours, split, activePane, per-pane viewMode/sort/hidden/iconSize, activeTabID, closedTabs) | unit (temp `fileURL`) | `swift test --filter SessionStoreTests` | ❌ Wave 0 |
| TAB-06 | corrupt file → `restore()` returns nil (no crash); missing path → nearest ancestor; unknown viewMode string → default | unit | `swift test --filter SessionStoreTests` | ❌ Wave 0 |
| TAB-06 | debounced autosave writes within ~0.6s after a mutation (await `Task.sleep(for: .milliseconds(800))`) | unit (async test) | `swift test --filter SessionStoreTests` | ❌ Wave 0 |
| TAB-06 | ⌘Q, relaunch: same tabs on the first frame | GUI (rm session.json, set up tabs, **⌘Q**, `open Shark.app`, screenshot) | manual-driven | n/a |
| TAB-07 | `open(_:from:newTab:true)` inserts a background tab after current, selection unchanged; locked owner opens a foreground tab after it; `selectTab(number:)` 1–8 and 9 = last, N > count is a no-op | unit | `swift test --filter WorkspaceStateTests` | ❌ Wave 0 |
| TAB-07 | ⌥⌘1–9, ⌃Tab, ⌃⇧Tab, ⇧⌘[ and ⇧⌘], ⌘-double-click, ⌘-click sidebar | GUI (cua-driver hotkeys and modifier clicks) | manual-driven | n/a |

**Test isolation rule:** `SessionStoreTests` **must** construct `SessionStore(fileURL: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json"))`. A test must never touch the real `~/Library/Application Support/Shark/session.json`.

### GUI verification script (cua-driver)
1. `rm -f ~/Library/Application\ Support/Shark/session.json && scripts/run.sh`, then `list_windows({app:"Shark"})`.
2. Strip checks: 1 tab is visible, ⌘T ×3, hover close, tooltip, screenshot in light and dark.
3. Context menu: run every item. Then read the Tab menu (Recently Closed state).
4. Drag a tab, dwelling at the target (Pitfall 10); middle-click a tab (Pitfall 9).
5. ⌘-double-click a folder (background tab appears and selection is unchanged); lock a tab, double-click a folder (new foreground tab).
6. Set up pins, colours, split, view modes, then **⌘Q** (not pkill), wait 1s, `open Shark.app`, take a screenshot and compare.

### Sampling Rate
- **Per task commit:** `swift test --filter WorkspaceStateTests` (or `SessionStoreTests`) plus `swift build`
- **Per wave merge:** `swift test`
- **Phase gate:** `swift test` green, plus the cua-driver GUI script with screenshots, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `Tests/SharkTests/SessionStoreTests.swift`: covers TAB-06 (round-trip, corrupt, fallback, debounce)
- [ ] Extend `Tests/SharkTests/WorkspaceStateTests.swift`: TAB-02, 03, 04, 05, 07 model ops
- [ ] `SessionStore.init(fileURL:)` injection point (design requirement for testability)

## Security Domain

`security_enforcement: true`, ASVS level 1. This is a local desktop app with no network, authentication or secrets.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no (here "session" means UI workspace state, not auth) | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `session.json` is untrusted input: `Codable` decode inside `do/catch` (failure → fresh); cap `closedTabs` at 20 and tabs at a sane maximum (e.g. 200) on restore; paths standardized and checked for existence before use |
| V6 Cryptography | no | — |
| V7 Error Handling & Logging | yes | `os.Logger`. Interpolated values are private by default, so restored paths are not leaked to the unified log. No dialogs. |
| V12 Files & Resources | yes | Only writes to `Application Support/Shark/session.json`, `.atomic`; never deletes or modifies the user files named in the snapshot. Restored paths only drive navigation. |

### Known Threat Patterns for a SwiftUI desktop app persisting paths

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered or corrupt `session.json` crashes the launch | Denial of Service | Decode in `do/catch`; drop invalid entries; never `try!` or force-unwrap |
| Oversized `session.json` (huge arrays) slows launch | Denial of Service | Cap tabs and closedTabs on restore |
| Restored path on a hung network mount blocks main-thread `fileExists` at launch | Denial of Service | Accept for v1 (PRODUCT scope: local disks and mounted volumes); note it. Only active panes load listings. |
| Partial write on crash | Tampering (integrity) | `.atomic` write |
| Paths in logs | Information disclosure | `Logger` privacy defaults; log the error, not the snapshot |

## Sources

### Primary (HIGH confidence)
- **Probe apps built this session** (Swift 6, `-target arm64-apple-macosx14.0`, run on macOS 26.6 and driven via System Events and CGEvent). They verified:
  - Commands observe `@Observable`.
  - `.saveItem` replacement takes ⌘W.
  - `CommandMenu("View")` duplicates the View menu.
  - Tab is placed after View.
  - Conditional Recently Closed works, and `.disabled` on `Menu` does not.
  - ⌃Tab, ⌃⇧Tab, ⌥⌘1, ⇧⌘] and ⇧⌘T dispatch; hidden-button ⇧⌘[ and ⇧⌘] fire; the F4 `NSF4FunctionKey` equivalent fires.
  - `allowsAutomaticWindowTabbing = false` removes Show Tab Bar.
  - `applicationWillTerminate` runs on ⌘Q and not on SIGTERM.
  - The hover + local-monitor middle-click works and the hitTest overlay does not.
  - Both drag APIs complete drops when the drag dwells.
  - `withObservationTracking`, `DropDelegate`, `NSEvent` monitor and `@MainActor AppDelegate` initialisers typecheck.
- Codebase files read this session: `SharkApp.swift`, `State/WorkspaceState.swift`, `State/WorkspaceTab.swift`, `State/NavigationState.swift`, `Views/ContentView.swift`, `Views/Workspace/TabBarView.swift`, `Views/Workspace/DualPaneContainerView.swift`, `Views/Directory/DirectoryView.swift`, `IconsGridView.swift`, `DetailsTableView.swift`, `PlacesSidebarView.swift` (rows), `BreadcrumbBarView.swift`, `Tests/SharkTests/WorkspaceStateTests.swift`, `scripts/run.sh`, `scripts/hot_reload.py`, `Package.swift`
- [Apple: Window](https://developer.apple.com/documentation/swiftui/window): a single-window primary scene quits the app when the window closes
- [Apple: CommandGroupPlacement](https://developer.apple.com/documentation/swiftui/commandgroupplacement): `.saveItem` covers "save open documents and close windows"
- [Apple: dropDestination(for:action:isTargeted:)](https://developer.apple.com/documentation/swiftui/view/dropdestination(for:action:istargeted:)): signature and the `macOS 13.0 – 27.2` availability

### Secondary (MEDIUM confidence)
- [Apple Developer Forums 812113](https://developer.apple.com/forums/thread/812113): macOS 26.2 hit-testing regression with layered NSHostingViews (consistent with the failed overlay probe)
- [Apple Developer Forums 667768](https://developer.apple.com/forums/thread/667768): older reports of Commands not refreshing (superseded on 26.6 by the probe)

### Tertiary (LOW confidence)
- [WWDC26 session 271 index](https://developer.apple.com/videos/play/wwdc2026/271/): new reordering API (not usable at a macOS 14 target)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new deps; every API typechecked against the real SDK at the macOS 14 target.
- Architecture: HIGH. Ownership, Commands, terminate and autosave were probe-verified. Lock routing is a design choice (A7).
- Pitfalls: HIGH for 1–4 and 9–11 (probe- or code-verified); MEDIUM for 5 and 6 (reasoned, GUI-check).

**Research date:** 2026-10-20
**Valid until:** 2026-11-20 (stable platform APIs; re-check only if the deployment target moves past macOS 14)
