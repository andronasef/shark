# Phase 7: Pro Tab Strip & Session Restore - Pattern Map

**Mapped:** 2026-10-20
**Files analyzed:** 14
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Sources/Shark/SharkApp.swift` (mod: AppDelegate owns workspace+store, TabCommands, View group fix) | config/app | event-driven | itself (lines 1-48) | exact |
| `Sources/Shark/State/WorkspaceState.swift` (mod: pin/lock/colour/move/duplicate/closeOthers/closeRight/reopen/selectTab(number:)/open) | store | CRUD | itself (lines 32-73) | exact |
| `Sources/Shark/State/WorkspaceTab.swift` (mod: isPinned, isLocked, color; `PaneIdentifier: Codable`) | model | CRUD | itself | exact |
| `Sources/Shark/State/WorkspaceSnapshot.swift` (new) | model | transform | `State/WorkspaceTab.swift` lines 4-7 (public Sendable enum) | role-match |
| `Sources/Shark/State/SessionStore.swift` (new) | service | file-I/O | none in repo (RESEARCH Pattern 6) | partial |
| `Sources/Shark/Views/Workspace/TabStripView.swift` (new, replaces TabBarView) | component | event-driven | `Views/Workspace/TabBarView.swift` | exact |
| `Sources/Shark/Views/Workspace/TabItemView.swift` (new) | component | event-driven | `TabBarView.swift` lines 35-69 | exact |
| `Sources/Shark/Views/Workspace/MiddleClick.swift` (new) | utility (view modifier + NSEvent monitor) | event-driven | none (RESEARCH Pattern 3) | none |
| `Sources/Shark/Views/Workspace/TabBarView.swift` | — | — | DELETE | — |
| `Sources/Shark/Views/ContentView.swift` (mod: injected workspace, `.environment`, `.id(activeTabID)`, remove ⇧⌘T, add ⇧⌘[ ⇧⌘]) | component | request-response | itself lines 8, 36-52, 345-361 | exact |
| `Sources/Shark/Views/Directory/DirectoryView.swift` (mod: handleActivate → `workspace.open`) | component | event-driven | itself lines 291-297 | exact |
| `Sources/Shark/Views/Sidebar/PlacesSidebarView.swift` (mod: row action → `open`, `.onMiddleClick`) | component | event-driven | itself lines ~121-123 | exact |
| `Tests/SharkTests/WorkspaceStateTests.swift` (extend) | test | CRUD | itself lines 1-40 | exact |
| `Tests/SharkTests/SessionStoreTests.swift` (new) | test | file-I/O | `WorkspaceStateTests.swift` | role-match |
| `CHANGELOG.md` (mod, `[Unreleased]`) | docs | — | existing file | exact |

## Pattern Assignments

### `SharkApp.swift` (app/config)
**Current** (lines 4-17, 19-47): AppDelegate is non-isolated, `ContentView()` takes no args, and `CommandMenu("View")` has empty `// Handled in ContentView` actions.
```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        ...
@main
struct SharkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup { ContentView().frame(minWidth: 850, minHeight: 550) }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands { SidebarCommands(); CommandMenu("View") { ... } }
```
**Changes:**
- Mark AppDelegate `@MainActor`.
- Add `let session = SessionStore()` and `workspace = session.restore() ?? WorkspaceState()`.
- Set `NSWindow.allowsAutomaticWindowTabbing = false` in `willFinishLaunching`.
- In `didFinishLaunching`, call `MiddleClick.install()` and `session.startAutosave(workspace)`.
- In `applicationWillTerminate`, call `session.saveNow(workspace)`.
- Replace `CommandMenu("View")` with `CommandGroup(after: .toolbar)` and wire it to real actions, including F4 for the terminal.
- Add `struct TabCommands: Commands` in this file (RESEARCH Pattern 1).

### `State/WorkspaceState.swift` (store, CRUD)
**Class shape** (lines 1-14): `import Foundation; import Observation; @Observable @MainActor public final class`. Keep this shape and add `init(snapshot:)`, `snapshot()`, `closedTabs`, and `isTerminalVisible` (not persisted).

**Mutation style to copy** (lines 39-73):
```swift
public func closeTab(id: UUID) {
    guard tabs.count > 1 else { ... return }
    if let index = tabs.firstIndex(where: { $0.id == id }) {
        let closingActive = (id == activeTabID)
        tabs.remove(at: index)
        if closingActive { activeTabID = tabs[min(index, tabs.count - 1)].id }
    }
}
public func nextTab() {
    guard tabs.count > 1, let index = tabs.firstIndex(where: { $0.id == activeTabID }) else { return }
    activeTabID = tabs[(index + 1) % tabs.count].id
}
```
- Every op uses guard + `firstIndex(where:)` and silently no-ops on a missing id. Follow that.
- Change `newTab` (lines 32-37) from `tabs.append` to an insert clamped to `>= pinnedCount`.
- Change `closeTab` so the last-tab case pushes the tab to history and replaces it with a fresh Home tab, instead of `navigateTo(home)`.
- Remove the mutating fallback in the `activeTab` getter (lines 16-26), or keep it unreachable by maintaining the never-empty invariant.
- Rules for each op: RESEARCH Pattern 5 table.

### `State/WorkspaceTab.swift` (model)
- Add `public var isPinned = false`, `public var isLocked = false`, and `public var color: TabColor?`.
- Change line 4 to `public enum PaneIdentifier: String, CaseIterable, Codable, Sendable`.
- `title` (lines 37-44) already exists; build the tooltip helper next to it (RESEARCH "Tooltip text").

### `State/WorkspaceSnapshot.swift` (model, transform, new)
**Analog:** the enum declaration style in WorkspaceTab.swift lines 4-7 (`public`, `Sendable`). Copy the struct set from RESEARCH Pattern 7. Persist case names, not rawValues (Pitfall 8). `existingAncestor(_:)` lives here.

### `State/SessionStore.swift` (service, file-I/O, new)
No analog; use RESEARCH Pattern 6 verbatim.
- There is no `os.Logger` usage in the repo. Add `private let logger = Logger(subsystem: "Shark", category: "Session")`.
- Inject `fileURL` through the init.

### `Views/Workspace/TabStripView.swift` + `TabItemView.swift` (component)
**Analog:** `Views/Workspace/TabBarView.swift` (delete it after porting).

Header/injection pattern (lines 1-10, 96):
```swift
import SwiftUI
import Inject

public struct TabBarView: View {
    @ObserveInjection var inject
    @Bindable var workspaceState: WorkspaceState
    public init(workspaceState: WorkspaceState) { self.workspaceState = workspaceState }
    public var body: some View { ... .enableInjection() }
}
```
Tab button and close pattern (lines 35-69). Replace the selection Button with `.onTapGesture` plus the strip layout from UI-SPEC:
```swift
ForEach(workspaceState.tabs) { tab in
    let isActive = (tab.id == workspaceState.activeTabID)
    Button(action: { workspaceState.selectTab(id: tab.id) }) {
        HStack(spacing: 6) {
            ...
            Button(action: { workspaceState.closeTab(id: tab.id) }) {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
            }.buttonStyle(.plain)
        }
    }.buttonStyle(.plain)
}
```
"+" button with `.help("New Tab (⌘T)")` (lines 73-83). Keep it.

The context menu style comes from `Views/Directory/IconsGridView.swift:42` (`.contextMenu { ... }`).

**Copy Path** source: `Views/Inspector/InspectorPanelView.swift:136-137`:
```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(meta.url.path, forType: .string)
```
Drag/drop: RESEARCH Pattern 4. Layout: Pattern 2.

### `Views/Workspace/MiddleClick.swift` (utility, new)
No analog. The only AppKit bridge in the repo is `Terminal/TerminalView.swift:5` (`NSViewRepresentable`), and RESEARCH found the overlay approach failed. Use RESEARCH Pattern 3 verbatim.

### `Views/ContentView.swift` (modify)
- Line 8: change `@State private var workspaceState = WorkspaceState()` to `let workspaceState: WorkspaceState`, and add `.environment(workspaceState)` at the root.
- Line 41: change `TabBarView(workspaceState: workspaceState)` to `TabStripView(workspaceState: workspaceState)`.
- Line 50: append `.id(workspaceState.activeTabID)` to `DualPaneContainerView(tab: workspaceState.activeTab)` (Pitfall 5).
- Hidden-button block (lines 345-361):
```swift
.background {
    Group {
        Button("") { ... }.keyboardShortcut("1", modifiers: .command)
        ...
        Button("") { toggleTerminalDrawer() }.keyboardShortcut("t", modifiers: [.command, .shift])   // DELETE (Pitfall 1)
    }
    .opacity(0)
    .allowsHitTesting(false)
}
```
  Add only `⇧⌘]` → `nextTab()` and `⇧⌘[` → `previousTab()` here. Move the terminal visibility `@State` to `workspaceState.isTerminalVisible`.
- Path popover rows (lines 450-453): change `navigationState.navigateTo(url)` to `workspace.open(url, from: navigationState, newTab: NSEvent.modifierFlags.contains(.command))`, and add `.onMiddleClick`.

### `Views/Directory/DirectoryView.swift` (modify, lines 291-297)
```swift
private func handleActivate(_ item: FileItem) {
    if item.isNavigableDirectory {
        navigationState.navigateTo(item.url)      // → workspace.open(item.url, from: navigationState, newTab: NSEvent.modifierFlags.contains(.command))
    } else {
        NSWorkspace.shared.open(item.url)
    }
}
```
- Add `@Environment(WorkspaceState.self) private var workspace`.
- Add `.onMiddleClick` on folder items in `IconsGridView` and `DetailsTableView`, next to the existing `.contextMenu` (IconsGridView:42, DetailsTableView:43).

### `Views/Sidebar/PlacesSidebarView.swift` (modify)
```swift
Button(action: {
    navigationState.navigateTo(url)     // → workspace.open(url, from: navigationState, newTab: ⌘ held)
}) { HStack(spacing: 10) { ... } }
```
Add `.onMiddleClick { workspace.open(url, from: navigationState, newTab: true) }`.

### Tests (`WorkspaceStateTests.swift` extend, `SessionStoreTests.swift` new)
**Analog:** `Tests/SharkTests/WorkspaceStateTests.swift` lines 1-11:
```swift
import XCTest
@testable import Shark

@MainActor
final class WorkspaceStateTests: XCTestCase {
    var workspace: WorkspaceState!
    let homeURL = FileManager.default.homeDirectoryForCurrentUser
    override func setUp() async throws { workspace = WorkspaceState(initialURL: homeURL) }
```
SessionStoreTests must use a temp `fileURL` (`temporaryDirectory.appending(path: UUID().uuidString + ".json")`) and remove it in `tearDown`.

## Shared Patterns

- **State classes:** `@Observable @MainActor public final class`. Any type in a public property is `public` + `Sendable`.
- **Views:** `@ObserveInjection var inject` + `.enableInjection()`, with `@Bindable var workspaceState`.
- **Navigation routing:** every folder activation from a pane, sidebar or popover goes through `workspace.open(_:from:newTab:)`. Only `NavigationState.navigateTo` remains inside it.
- **Commands only, no hidden buttons**, except ⇧⌘[ and ⇧⌘] (one key equivalent per menu item).
- **Pasteboard:** `InspectorPanelView.swift:136-137`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `State/SessionStore.swift` | service | file-I/O | No persistence or Logger exists yet; use RESEARCH Pattern 6 |
| `Views/Workspace/MiddleClick.swift` | utility | event-driven | No NSEvent monitors in the repo; use RESEARCH Pattern 3 |

## Metadata
**Analog search scope:** `Sources/Shark/**`, `Tests/SharkTests/**`
**Files scanned:** 12
**Pattern extraction date:** 2026-10-20
