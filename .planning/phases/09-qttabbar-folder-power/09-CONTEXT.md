# Phase 9: QTTabBar Folder Power — Context

## Goal
Implement QTTabBar's signature features that give users unprecedented speed and power in folder navigation:
1. **Cascading Subfolder Menus (Breadcrumbs & Folder Items)**:
   - Each breadcrumb segment has a disclosure arrow / chevron opening a cascading native `NSMenu` of child directories and files.
   - Clicking a child navigates immediately to it; ⌘-clicking opens it in a new tab.
   - Folder rows and icons expose "Browse ▸" cascading subfolder menus on hover or right-click.
2. **Hover Quick-Previews**:
   - Hovering over an image displays a crisp thumbnail popover.
   - Hovering over a text/code file shows a syntax/text preview popover showing the first lines.
   - Debounced (350ms) to prevent unwanted popovers during cursor movement.
   - Can be toggled on/off in preferences.
3. **Recent & Frequent Folders Engine**:
   - Tracks directory visits with timestamps and hit counts.
   - Exposes Recent Folders (last 30 visited) and Frequent Folders (top ranked by visits) in Sidebar, Go menu, and workspace state.
4. **Saved Tab Groups**:
   - Ability to save the current open tabs (with paths, colors, split configuration) as a named Tab Group (e.g. "Dev", "Downloads & Docs", "Work").
   - Ability to recall/load a Tab Group, replacing or appending to the current window.
   - Tab groups persist in `Application Support/Shark/tab_groups.json`.

## Architecture & Integration Points
- **RecentFoldersService**: Tracks MRU (up to 30) and MFU directories with visit frequencies, persisting to `recent_folders.json`.
- **TabGroupService**: Models `TabGroup` with list of tab snapshots, provides `saveGroup(name:from:)`, `restoreGroup(_:into:)`, and persistence in `tab_groups.json`.
- **SubfolderMenuBuilder**: Builds lazy or dynamic `NSMenu` hierarchies for any given directory URL, enumerating child folders and files with appropriate icons, supporting arbitrary nesting depth and modifier clicks.
- **HoverPreviewCoordinator**: Manages hover detection, debounce timer (350ms), thumbnail generation or text snippet extraction, and popover presentation.
