# Phase 7: Pro Tab Strip & Session Restore - Context

**Gathered:** 2026-10-20
**Status:** Ready for planning
**Mode:** Smart discuss, recommended answers auto-accepted (the user asked for fully autonomous execution)

<domain>
## Phase Boundary

Replace the current `TabBarView` (Finder sub-toolbar capsule) with a full QTTabBar-grade tab strip that looks like Finder/Safari tabs, supports reorder, pin, lock, colour, duplicate, close variants, reopen-closed history, and persists the whole workspace (tabs, panes, view modes) across relaunch. Navigation features (subfolder menus, palette) are later phases.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `WorkspaceState` (State/WorkspaceState.swift): tabs array, activeTabID, newTab/closeTab/selectTab/nextTab/previousTab — extend rather than replace.
- `WorkspaceTab` (State/WorkspaceTab.swift): id, isSplit, activePane, primary/secondary `NavigationState`, `title`.
- `NavigationState`: currentURL, viewMode, sortField, sortAscending, showHiddenFiles, iconSize — all must be captured by the snapshot.
- `TabBarView` (Views/Workspace/TabBarView.swift): to be replaced by the new strip.
- `DirectoryView.handleActivate` and sidebar navigation: the hook points for lock behaviour and ⌘-open-in-new-tab.

### Established Patterns
- `@Observable @MainActor` state classes; SwiftUI views with `@Bindable`; AppKit bridging via NSViewRepresentable; `Inject` hot reload (`@ObserveInjection` + `.enableInjection()`) on main views.
- Swift 6 strict concurrency; tests in Tests/SharkTests using XCTest on state classes (e.g. WorkspaceStateTests).
- Keyboard shortcuts currently registered via hidden zero-opacity buttons in ContentView `.background` — move tab ones to `Commands` with `FocusedValue`/`@FocusedObject` or a shared app-level state.

### Integration Points
- `ContentView` owns `@State workspaceState`; for Commands and session save on terminate it should move to an app-level owner (e.g. `SharkApp` holds it and passes it down / via `focusedSceneValue`).
- `AppDelegate.applicationWillTerminate` for synchronous save.

</code_context>

<specifics>
## Specific Ideas

- Look: macOS Finder tabs (and Safari) — equal-width, hairline separated, close on hover. Power: QTTabBar (pin, lock, colour, reopen closed, middle-click, session restore).
- Verify by driving the running app with cua-driver (scripts/run.sh to launch).

</specifics>

<deferred>
## Deferred Ideas

- Tab groups (saved sets) → Phase 9 (QT-05).
- Setting to hide the strip with one tab → Phase 10 Settings (CMD-04).
- Dragging a tab out to a new window / between windows → later milestone.

</deferred>
