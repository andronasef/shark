# Changelog

All notable changes to the Shark file manager project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Native Finder Design Alignment**:
  - Authentically aligned window layout, navigation bar, and icon grid with macOS Finder.
  - Leading navigation group featuring Back/Forward navigation history buttons alongside the active folder's system icon and title.
  - Flexible center space (`.principal Spacer`) distributing action controls cleanly to the trailing edge of the window toolbar.
  - Discrete popovers for **Path Hierarchy**, **Group & Sort**, and **Action Menu**, replacing default `Menu` items to eliminate AppKit disclosure triangles and button clipping.
  - Segmented View Mode control (`[ ⊞ | ≣ | ☷ | 🗔 ]`) with intrinsic 176pt width and balanced padding to prevent control overlaps.
  - Finder-styled sub-toolbar single-tab capsule displaying centered active folder name and `+` button.
  - macOS Places sidebar structured into *Recents*, *Shared*, *Favorites*, *Locations*, and *Tags*.
- **SwiftTerm Terminal Emulation**:
  - Integrated `SwiftTerm` (`SwiftTermView`) replacing raw text terminal views.
  - Full VT100/xterm ANSI escape sequence rendering, cursor management, and keyboard handling.
  - Bidirectional directory sync between active file browser navigation and the embedded terminal session.
- **Developer Hot Reload**:
  - Integrated `Inject` package for runtime SwiftUI view injection.
  - Added `@ObserveInjection` and `.enableInjection()` across key views (`ContentView`, `PlacesSidebarView`, `DirectoryView`, `IconsGridView`, `TabBarView`).
  - Added standalone development runner [`scripts/dev.sh`](scripts/dev.sh) and python file watcher [`scripts/hot_reload.py`](scripts/hot_reload.py).

### Fixed
- Fixed Command + scroll wheel icon resizing by intercepting scroll events within the hovered directory pane without blocking normal clicks or scrolling.
- Fixed top bar overlap where the View segmented control collided with the Path button.
- Fixed duplicated button titles and unwanted `⌵` chevrons drawn by AppKit's `NSMenuToolbarItem`.
- Fixed window toolbar layout packing all items against the left side rather than trailing right.
- Fixed root traversal hanging and `NSTextView` designated initializer crash in earlier terminal integration.

---

## [0.6.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **File Operations Engine**:
  - New Folder and New File creation with automatic naming collision resolution (`Folder`, `Folder 2`, etc.).
  - Duplicate item functionality (`⌘D`) appending "copy" or incrementing counters.
  - Move to Trash (`⌘⌫`) with system trash integration.
  - Drag-and-drop file movement between split panes and external apps.
  - Batch Rename tool with Find/Replace, Prefix/Suffix, numbering, and case conversions.
  - Real-time directory monitoring via `FSEvents` stream.

---

## [0.5.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Information & Metadata Inspector**:
  - Right-side collapsible Inspector panel (`⌥⌘I`).
  - POSIX file permissions display and octal representation (e.g. `0755` / `rwxr-xr-x`).
  - Asynchronous SHA-256 cryptographic checksum calculation with copy-to-clipboard.
  - File size formatting, item count for directories, creation and modification timestamps.

---

## [0.4.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Embedded Terminal Drawer**:
  - Collapsible bottom terminal drawer toggled via `F4` or toolbar button.
  - PTY pseudo-terminal session running user shell (`$SHELL`).
  - Directory synchronization tracking file navigation.

---

## [0.3.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **View Modes & Quick Look**:
  - Icons grid view (`⌘1`), Details list view (`⌘2`), Compact columns (`⌘3`), and Gallery (`⌘4`).
  - Instant live filename filtering (`⌘I`).
  - Quick Look integration with macOS `QLPreviewPanel` on Spacebar press.

---

## [0.2.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Dual-Pane Split & Tabbed Browsing**:
  - Split view support (`⇧⌘S`) for dual-pane file management inspired by KDE Dolphin.
  - Tab management (`⌘T` new tab, `⌘W` close tab).

---

## [0.1.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- Initial project foundation in native Swift and SwiftUI.
- Filesystem enumeration, volume detection, and navigation state.
- Standard macOS sidebar places and directory listing.
