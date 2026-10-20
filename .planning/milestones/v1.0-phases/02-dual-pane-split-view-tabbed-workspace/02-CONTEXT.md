# Phase 2: Dual-Pane Split View & Tabbed Workspace - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin F3 Split View & Tabs)

<domain>
## Phase Boundary

Implement Dolphin's core signature feature: Dual-pane split view (toggled by F3) and a robust multi-tab system (Cmd+T / Cmd+W).
Enable two independent directory browsers side-by-side with active pane tracking, visual focus cues, and tab persistence.

Requirements covered: SPLIT-01, SPLIT-02, SPLIT-03.
</domain>

<decisions>
## Implementation Decisions

### 1. Dual-Pane Architecture
- Define `PaneIdentifier`: `.primary` and `.secondary`.
- `WorkspaceTab` models a single tab which owns:
  - `primaryPane: NavigationState`
  - `secondaryPane: NavigationState` (initialized or activated when split)
  - `isSplit: Bool` (toggled by F3)
  - `activePane: PaneIdentifier`
- Active pane tracking: Clicking in a pane sets it as active. The top toolbar (breadcrumbs, back/forward, search, view mode) automatically routes commands to the currently active pane.
- Active pane visual indicator: Subtle accent-colored outline / header tinting that clearly shows which pane is receiving keyboard and navigation inputs.

### 2. Multi-Tab Management
- `WorkspaceState`: Root `@Observable` managing an array of `WorkspaceTab`s and `activeTabID: UUID`.
- Dolphin-style tab bar above or integrated with the main content area:
  - Tab title reflects directory name (e.g. "Documents" or "Documents | Downloads" when split).
  - Close button on hover/selected tab.
  - Plus button to open new tab (`Cmd+T`).
  - Close tab (`Cmd+W`), preventing closing the last tab or resetting it to Home.
  - Tab switching via click or `Cmd+1...9` / `Cmd+Shift+[` / `Cmd+Shift+]`.

### 3. Split-Pane Operations
- When F3 is pressed:
  - If not split, splits the view. The secondary pane opens to either the same directory or a user default.
  - If split, collapses back to single pane (retaining primary pane).
- Pressing `Tab` key toggles active focus between Left and Right panes.
- Copy/Move between panes (prepared for Phase 6 file ops).

</decisions>
