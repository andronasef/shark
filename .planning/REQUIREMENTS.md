# Requirements: Shark (Dolphin for macOS)

**Defined:** 2026-10-13
**Core Value:** Bring KDE Dolphin's dual-pane, terminal-integrated, and keyboard-centric file management workflow to macOS users as a high-performance native application.

## v1 Requirements

### Core Navigation & Sidebar (CORE)

- [x] **CORE-01**: User can browse any local directory with high-performance async loading and smooth scrolling.
- [x] **CORE-02**: User can navigate via Places sidebar including System Volumes, User Folders (Home, Desktop, Downloads, Documents), and Trash.
- [x] **CORE-03**: User can pin custom folders to the Favorites section in the sidebar.
- [x] **CORE-04**: User can navigate via clickable breadcrumbs and toggle direct path text editing (`Cmd+L`).
- [x] **CORE-05**: User can use history navigation (Back `Cmd+[`, Forward `Cmd+]`, Up `Cmd+Up`).

### Split-Pane & Tabs (SPLIT)

- [x] **SPLIT-01**: User can toggle dual-pane split view (`F3`) to browse two directories side by side.
- [x] **SPLIT-02**: User can switch active pane via keyboard (`Tab` or mouse click) with clear visual focus styling.
- [x] **SPLIT-03**: User can open, close, and reorder tabs (`Cmd+T`, `Cmd+W`), with each tab preserving its own path, view mode, and split state.

### View Modes & Filtering (VIEW)

- [x] **VIEW-01**: User can switch between Details/Table view, Grid/Icons view, and Compact List view.
- [x] **VIEW-02**: User can sort items in Details view by Name, Size, Date Modified, Kind, and Permissions.
- [x] **VIEW-03**: User can adjust icon/thumbnail zoom level in Grid view.
- [x] **VIEW-04**: User can instantly filter the active directory using the live filter bar (`Cmd+I`).
- [x] **VIEW-05**: User can trigger native Quick Look preview on selected items using `Space`.

### Embedded Terminal Drawer (TERM)

- [x] **TERM-01**: User can toggle the embedded bottom terminal drawer (`F4`).
- [x] **TERM-02**: Terminal runs an interactive pseudo-terminal (PTY) with the user's login shell ($SHELL, e.g. zsh).
- [x] **TERM-03**: Terminal tracks the active pane's working directory upon pane change or file navigation.

### Information Inspector (INSP)

- [x] **INSP-01**: User can toggle the right-hand Information / Inspector panel (`F11`).
- [x] **INSP-02**: Inspector displays rich metadata including file size, POSIX permissions, owner/group, MIME type, image dimensions, audio/video duration, and file hashes.

### File Operations & Live Updates (OPS)

- [x] **OPS-01**: User can perform non-blocking file operations: Copy, Move, Duplicate, Move to Trash, and Delete.
- [x] **OPS-02**: User can create new folders (`Cmd+Shift+N`) and new empty files.
- [x] **OPS-03**: User can rename files inline and perform multi-file batch renames.
- [x] **OPS-04**: Directory views automatically refresh in real-time when external changes happen using macOS `FSEvents``.
- [x] **OPS-05**: User can drag and drop items between panes, to/from Finder, and to the sidebar.

## v2.0 Requirements — Finder look, QTTabBar + Explorer power

### Pro Tabs (TAB)
- [x] **TAB-01**: Full-width tab strip always visible, Finder/Safari style, equal-width tabs with hover close button and tooltip showing full path.
- [x] **TAB-02**: Drag tabs to reorder; middle-click closes a tab; double-click empty strip opens a new tab.
- [x] **TAB-03**: Reopen closed tab (⇧⌘T) from a closed-tab history (last 20), and a "Recently Closed" menu.
- [x] **TAB-04**: Tab context menu: Duplicate, Pin/Unpin, Lock (navigation opens new tab), Close Others, Close Tabs to the Right, Colour (tint dot), Copy Path.
- [x] **TAB-05**: Pinned tabs render compact (icon only) at the left and survive Close Others.
- [x] **TAB-06**: Session restore: tabs, pins, locks, colours, paths, split state and view mode persist across relaunch.
- [x] **TAB-07**: Open folder in new tab via ⌘-double-click, ⌘-click on sidebar/breadcrumb, or middle-click; ⌥⌘1–9 select tabs (⌘1–4 stay Finder view modes); ⌃Tab / ⌃⇧Tab cycle.

### Explorer Ergonomics (EXP)
- [x] **EXP-01**: Cut / Copy / Paste of files (⌘X, ⌘C, ⌘V; ⌥⌘V moves), works across tabs, panes and with Finder pasteboard; cut items render dimmed until pasted.
- [x] **EXP-02**: Undo/Redo (⌘Z/⇧⌘Z) for rename, move, copy, trash, new folder.
- [x] **EXP-03**: Inline rename with Return/F2 that selects the name without extension; validation errors inline.
- [x] **EXP-04**: Copy Path / Copy Name / Copy as Pathname (⌥⌘C) for one or many items.
- [x] **EXP-05**: Rich status bar: item count, selection count and total size, free space on volume, background job progress with cancel.
- [x] **EXP-06**: Optional Finder-style path bar at the bottom (⌥⌘P) with clickable segments.
- [x] **EXP-07**: Folder size calculation on demand (Calculate All Sizes) shown in list view and inspector, computed off main thread.
- [x] **EXP-08**: "Open in Terminal", "Open With ▸", "New Folder with Selection", "Compress", "Show Hidden Files" (⇧⌘.) toggle, all in context menus and menu bar.
- [x] **EXP-09**: Address bar: click empty area or ⌘L to edit path, Tab autocompletion of path segments, ~ expansion, error state on bad path.

### QTTabBar Folder Power (QT)
- [x] **QT-01**: Each breadcrumb segment has a chevron that opens a cascading subfolder menu; menus nest on hover to any depth; selecting navigates (⌘ opens in new tab).
- [x] **QT-02**: Folder rows/icons in list view expose a subfolder menu on hover of a disclosure chevron or via context menu "Browse ▸".
- [x] **QT-03**: Hover previews: images show a thumbnail popover, text/code files show the first lines, after a short hover delay; can be disabled in settings.
- [x] **QT-04**: Recent folders (last 30) and Frequent folders (ranked by visits) available in sidebar section, Go menu and palette.
- [x] **QT-05**: Tab groups: save current tabs as a named group, reopen a group from sidebar/menu/palette.

### Command Palette & Keys (CMD)
- [x] **CMD-01**: ⌘K / ⇧⌘P command palette with fuzzy search across every action, recent/frequent folders, pinned favorites, tab groups and typed absolute paths.
- [x] **CMD-02**: Every action exists in the menu bar with its shortcut (File, Edit, View, Go, Tab, Window); F3 split, F4 terminal, F11 inspector, Space Quick Look work.
- [x] **CMD-03**: Type-to-select in all views; arrow-key navigation, Return to rename, ⌘↓ open, ⌘↑ enclosing folder.
- [x] **CMD-04**: Settings window (⌘,) for tab behaviour, hover preview, default view, show hidden, start location.

### Finder Polish (POL)
- [ ] **POL-01**: Visual fidelity to Finder in light and dark: toolbar, sidebar, list/icon/column/gallery, selection, focus rings, spacing.
- [ ] **POL-02**: A real Columns (Miller) view.
- [ ] **POL-03**: Empty, loading, error and permission-denied states that tell the user what to do.
- [ ] **POL-04**: VoiceOver labels, keyboard focus, Reduce Motion respected.
- [ ] **POL-05**: DESIGN.md documents the shipped system.
- [ ] **POL-06**: **Liquid Glass & Translucent Vibrancy**: Native macOS translucent materials (NSVisualEffectView / SwiftUI materials) across the window backdrop, unified toolbar, sidebar, tab strip, and floating preview cards, matching original Finder's liquid glass vibrancy with desktop wallpaper bleed-through in both light and dark modes.

## Later Requirements

### Remote & Advanced Integrations

- **REMT-01**: SFTP, SMB, and FTP remote folder browsing (KIO slave equivalents).
- **REMT-02**: Git status badges on file icons in repositories.
- **REMT-03**: Integrated file diff tool between left and right split panes.
- **REMT-04**: Archive extraction and compression with zip/tar/7z support.

## Traceability

- Shipped in v1.0: CORE-01..05, SPLIT-01..03, VIEW-01..05, TERM-01..03, INSP-01..02, OPS-01..05 (22 total)
- Shipped in v2.0: TAB-01..07, EXP-01..09, QT-01..05, CMD-01..04 (25 total)
- In progress v2.0: POL-01..06 (6 total)
