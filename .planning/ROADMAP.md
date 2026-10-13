# Roadmap: Shark (Dolphin for macOS)

## Overview

Shark delivers KDE Dolphin's power-user file management experience natively on macOS. This roadmap builds the application incrementally through 6 focused phases: from foundational async filesystem navigation and sidebar browsing, to dual-pane split views and tabs, multi-view modes with instant filtering, an embedded PTY terminal drawer, a rich metadata inspector, and a comprehensive file operations engine with live FSEvents observation and drag-and-drop.

## Phases

- [x] **Phase 1: Core Navigation & macOS Foundation** - Native Swift/SwiftUI app scaffolding, high-performance FileSystem service, Places sidebar, clickable/editable breadcrumb bar, and directory navigation.
- [x] **Phase 2: Dual-Pane Split View & Tabbed Workspace** - Dolphin F3 dual-pane split navigation, active pane focus management, and multi-tab browsing (Cmd+T / Cmd+W).
- [x] **Phase 3: View Modes, Instant Filtering & Quick Look** - Details/Table view with column sorting, Grid/Icons view with zoomable thumbnails, Compact view, live filter bar (Cmd+I), and native Quick Look (Space).
- [x] **Phase 4: Embedded Terminal Drawer (F4)** - Collapsible bottom terminal panel with native PTY running user login shell ($SHELL) and bidirectional directory synchronization.
- [x] **Phase 5: Information & Metadata Inspector (F11)** - Collapsible right-hand inspector with detailed metadata, POSIX permissions, media attributes, checksums, and preview.
- [x] **Phase 6: File Operations Engine, FSEvents & Drag-and-Drop** - Async non-blocking file operations (copy, move, trash, delete, batch rename), live FSEvents filesystem monitoring, and native drag-and-drop.

## Phase Details

### Phase 1: Core Navigation & macOS Foundation
**Goal**: Establish the native macOS application architecture, file system service, Places sidebar, breadcrumb location bar, and single-pane directory browsing.
**Depends on**: Nothing (first phase)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05
**Success Criteria** (what must be TRUE):
  1. User can launch Shark and browse any directory on their Mac.
  2. Sidebar shows system volumes, standard user locations (Home, Desktop, Downloads, Documents, Trash), and pinned favorites.
  3. Clicking any breadcrumb segment jumps to that ancestor directory, and pressing Cmd+L toggles direct text editing of the path.
  4. User can navigate forward, backward, and up using keyboard shortcuts (Cmd+[, Cmd+], Cmd+Up).
**Plans**: 1 plan

Plans:
- [x] 01-01: Build Swift 6 package / app structure, FileItem models, FileSystemService, PlacesSidebar, BreadcrumbBar, and DirectoryView.

### Phase 2: Dual-Pane Split View & Tabbed Workspace
**Goal**: Implement Dolphin's iconic dual-pane split view (F3) and full multi-tab workflow.
**Depends on**: Phase 1
**Requirements**: SPLIT-01, SPLIT-02, SPLIT-03
**Success Criteria** (what must be TRUE):
  1. Pressing F3 toggles the secondary file pane side-by-side with independent directory navigation.
  2. The active pane is visually distinguished with clear focus indicators, and pressing Tab cycles active pane.
  3. User can create new tabs (Cmd+T), switch tabs, and close tabs (Cmd+W), each preserving its own path and split configuration.
**Plans**: 1 plan

Plans:
- [x] 02-01: Build PaneState, WorkspaceTab, DualPaneContainer, TabBarView, and active pane keyboard coordination.

### Phase 3: View Modes, Instant Filtering & Quick Look
**Goal**: Provide Details/Table, Grid/Icons, and Compact views, instant in-memory filtering (Cmd+I), and Quick Look integration.
**Depends on**: Phase 2
**Requirements**: VIEW-01, VIEW-02, VIEW-03, VIEW-04, VIEW-05
**Success Criteria** (what must be TRUE):
  1. User can switch between Details/Table, Grid/Icons, and Compact views via toolbar or shortcuts.
  2. Details view supports sorting by Name, Size, Date Modified, Kind, and Permissions.
  3. Grid view supports thumbnail sizing zoom.
  4. Pressing Cmd+I opens the instant filter bar, filtering displayed files instantaneously as you type.
  5. Pressing Space opens the native macOS Quick Look panel for selected items.
**Plans**: 1 plan

Plans:
- [x] 03-01: Implement TableView, GridView, CompactView, LiveFilterBar, and QuickLookController.

### Phase 4: Embedded Terminal Drawer (F4)
**Goal**: Integrate Dolphin's iconic F4 terminal drawer powered by a real PTY running the user's shell.
**Depends on**: Phase 2
**Requirements**: TERM-01, TERM-02, TERM-03
**Success Criteria** (what must be TRUE):
  1. Pressing F4 smoothly toggles the bottom terminal drawer.
  2. The terminal runs an interactive pseudo-terminal session (forkpty/posix_spawn) executing the user's login shell.
  3. Changing directory in the active pane automatically synchronizes the terminal's working directory.
**Plans**: 1 plan

Plans:
- [x] 04-01: Build PTYSession, TerminalView (ANSI terminal emulator / NSViewRepresentable), and TerminalDrawer synced with active pane navigation.

### Phase 5: Information & Metadata Inspector (F11)
**Goal**: Build Dolphin's F11 inspector panel for deep file inspection and metadata exploration.
**Depends on**: Phase 1
**Requirements**: INSP-01, INSP-02
**Success Criteria** (what must be TRUE):
  1. Pressing F11 toggles the collapsible right-hand Information panel.
  2. Selecting any file reveals detailed size, POSIX permissions, owner/group, MIME type, dimensions/duration for media, and checksums.
**Plans**: 1 plan

Plans:
- [x] 05-01: Build InspectorPanel, MetadataExtractor (extended attributes, file stats, image/audio metadata, hashing), and preview header.

### Phase 6: File Operations Engine, FSEvents & Drag-and-Drop
**Goal**: Provide asynchronous file operations with progress, batch renaming, live FSEvents file system monitoring, and native drag-and-drop.
**Depends on**: Phase 3, Phase 5
**Requirements**: OPS-01, OPS-02, OPS-03, OPS-04, OPS-05
**Success Criteria** (what must be TRUE):
  1. User can copy, move, duplicate, trash, delete, and create files/folders asynchronously without UI freezes.
  2. User can select multiple files and batch-rename them with find-and-replace or numbered patterns.
  3. External modifications to directories (e.g. terminal or Finder file creation) immediately update the view via FSEvents.
  4. User can drag and drop files between split panes, to/from Finder, and onto sidebar folders.
**Plans**: 1 plan

Plans:
- [x] 06-01: Implement FileOperationsManager actor, BatchRenameSheet, FSEventsWatcher, and DragDropCoordinator.

---
*Roadmap defined: 2026-10-13*
*Last updated: 2026-10-13 - All 6 phases completed*
