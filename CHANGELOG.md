# Changelog

All notable changes to the Shark file manager project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Refined sidebar headings with hover feedback, keyboard focus outlines, arrow-key navigation, and temporary expansion during folder drags. Sidebar focus no longer triggers directory navigation shortcuts.
- Favorites now persist custom folders and order, support adding/reordering shortcuts with insertion guides, and offer Show in Finder, Locate Folder, and Remove from Favorites. Missing folders remain visible; removing a shortcut leaves its folder untouched. Ancestor indicators follow the active pane.
- Made sidebar sections collapsible with disclosure arrows, animated expansion, and remembered state; Reduce Motion disables transitions.
- Refined the top path capsule to fit short paths, use one menu chevron per segment, and show a neutral current-folder highlight. Long paths remain scrollable and editable.
- Moved Action after Split and Terminal, immediately before Search.
- Enlarged tabs to 28 pt within a 34 pt strip, increased label and close-button sizes, and added 200 ms open/close transitions with smooth width redistribution. Reduce Motion keeps changes immediate.
- Moved the breadcrumb path from the bottom of each directory pane into a glass Location capsule beside Back/Forward. Ancestor navigation, subfolder menus, path copying, and ⌘L editing remain available for the active pane.
- Corrected the tab strip to use equal-width, centered text tabs across the full available strip; removed unpinned folder icons and the inline Tab Groups control. Tab Groups remain on the add button’s context menu.
- Matched the toolbar and tabs to the supplied reference: capsule controls, captioned groups, a wider search field, and a full-width single-tab pill. Custom chrome uses native Liquid Glass on macOS 26+, with accessibility and older-system fallbacks; Split and Terminal buttons sit beside Action and highlight their active state.
- Matched the Places sidebar to the supplied reference with an inset rounded panel, larger monochrome icons, 32 pt rows, explicit section spacing, and brighter tag colors. Standard places now appear immediately while mounted volumes load.

### Fixed
- Long file names in the "Compress" context-menu item are now shortened in the middle, keeping the start and extension, so the menu stays compact.
- Text hover previews no longer fail when the first read ends mid-character, binary files are no longer previewed as text, and edited files no longer show a stale cached preview.
- Folders blocked by macOS privacy protection (e.g. Trash) now explain why and offer a button that opens Full Disk Access settings, instead of only "Try Again".

### Added
- **Deeper hover previews**: previews now appear in a non-activating floating panel so keyboard focus stays where it was, and the pointer can move into the panel to use its controls. Video and audio play inline with a seek bar (auto-play is optional), animated GIFs animate, images show at full resolution, text shows up to 40 lines with its detected encoding, and Office/iWork/RTF/PDF documents show a thumbnail. New settings: preview only while holding Shift, and auto-play media.
- **Liquid Glass adoption plan**: Documented proposed native Finder-style chrome, macOS 14/15 fallback, accessibility behavior, and visual acceptance checks. Implementation is pending.
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
- Connected the hover-preview setting and delay to file items in grid, list, column, and gallery views. Leaving an item, renaming, or disabling previews cancels pending previews.
- Stopped directory type-to-select and column navigation from consuming keystrokes while the embedded terminal has focus.
- Restored a visible Up button beside Back and Forward, navigating to the active pane’s parent folder.
- Fixed “Open in Terminal” on folder, background, and breadcrumb menus to explicitly launch Terminal.app rather than Finder. Added “Open in Embedded Terminal” at the clicked directory; files use their parent folder.
- Fixed the Terminal button and F4 failing to redraw the drawer by restoring observation of terminal visibility.
- Fixed split-pane focus: clicking or scrolling either pane now activates it before child controls handle input. Only the active pane registers navigation shortcuts, and inactive column views no longer intercept arrow keys.
- Made middle-click tab closing use the actual pointer position instead of a stale global hover target, scoped to the clicked window and visible tab region.
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
