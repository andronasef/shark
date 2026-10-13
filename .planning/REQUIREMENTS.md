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

- [ ] **OPS-01**: User can perform non-blocking file operations: Copy, Move, Duplicate, Move to Trash, and Delete.
- [ ] **OPS-02**: User can create new folders (`Cmd+Shift+N`) and new empty files.
- [ ] **OPS-03**: User can rename files inline and perform multi-file batch renames.
- [ ] **OPS-04**: Directory views automatically refresh in real-time when external changes happen using macOS `FSEvents`.
- [ ] **OPS-05**: User can drag and drop items between panes, to/from Finder, and to the sidebar.

## v2 Requirements

### Remote & Advanced Integrations

- **REMT-01**: SFTP, SMB, and FTP remote folder browsing (KIO slave equivalents).
- **REMT-02**: Git status badges on file icons in repositories.
- **REMT-03**: Integrated file diff tool between left and right split panes.
- **REMT-04**: Archive extraction and compression with zip/tar/7z support.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Qt / C++ KDE runtime emulation | Anti-pattern on macOS. Shark uses 100% native Swift, SwiftUI, and AppKit for optimal performance and native feel. |
| Cloud storage proprietary sync engines | Use standard mounted directories; Shark will not implement cloud sync clients. |
| System file write without authorization | Sandboxed / macOS permission guidelines respected; system files protected. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CORE-01 | Phase 1 | Complete |
| CORE-02 | Phase 1 | Complete |
| CORE-03 | Phase 1 | Complete |
| CORE-04 | Phase 1 | Complete |
| CORE-05 | Phase 1 | Complete |
| SPLIT-01 | Phase 2 | Complete |
| SPLIT-02 | Phase 2 | Complete |
| SPLIT-03 | Phase 2 | Complete |
| VIEW-01 | Phase 3 | Complete |
| VIEW-02 | Phase 3 | Complete |
| VIEW-03 | Phase 3 | Complete |
| VIEW-04 | Phase 3 | Complete |
| VIEW-05 | Phase 3 | Complete |
| TERM-01 | Phase 4 | Complete |
| TERM-02 | Phase 4 | Complete |
| TERM-03 | Phase 4 | Complete |
| INSP-01 | Phase 5 | Complete |
| INSP-02 | Phase 5 | Complete |
| OPS-01 | Phase 6 | Pending |
| OPS-02 | Phase 6 | Pending |
| OPS-03 | Phase 6 | Pending |
| OPS-04 | Phase 6 | Pending |
| OPS-05 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 23 total
- Completed: 18
- Mapped to phases: 23
- Unmapped: 0 ✓

---
*Requirements defined: 2026-10-13*
*Last updated: 2026-10-13 after Phase 5 completion*
