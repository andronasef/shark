# Phase 8: Explorer Ergonomics - Context & Analysis

## Phase Overview
Give Shark the everyday ease of Windows File Explorer and macOS Finder:
1. **Windows-style Cut/Copy/Paste (⌘X, ⌘C, ⌘V)** with dimming/opacity 0.5 feedback on cut items.
2. **Reversible Undo Stack (⌘Z, ⇧⌘Z)** for moves, copies, batch renames, and trash.
3. **Inline Rename**: Return/Enter key initiates inline renaming on selected item, pre-selecting file stem without extension.
4. **Forgiving Address Bar (⌘L / ⇧⌘G)**: Instant text mode toggle with path autocompletion, tilde expansion, and error resilience.
5. **Rich Status Bar & Bottom Path Bar**:
   - Status details: item count, selection count with aggregated size, volume available disk space.
   - Interactive Bottom Path Bar (Finder style, toggleable ⌥⌘P).
   - Async file copy/move progress indicator with Cancel button.
6. **Async Folder Sizes**: On-demand / background folder size computation.
7. **Extended Context Menu**: Open in Terminal, Compress (ZIP), Copy Path variations (POSIX, Quoted, Relative), Open With.

## Technical Requirements
- **Clipboard Service (`FileClipboardService`)**:
  - Manages cut/copied URLs and mode (`.cut`, `.copy`).
  - Publishes to system pasteboard (`NSPasteboard.general`) using `NSPasteboard.PasteboardType.fileURL`.
  - Exposes `isCut(url: URL) -> Bool` for view dimming.
- **Undo Manager (`FileUndoService`)**:
  - Records undoable actions: `.move(from: [URL], to: [URL])`, `.rename(old: URL, new: URL)`, `.trash(items: [URL])`.
  - Integrates with system `UndoManager` or native menu commands (⌘Z Undo, ⇧⌘Z Redo).
- **Inline Rename Field**:
  - Active in DetailsTableView and IconsGridView when an item has `isRenaming == true`.
  - Uses `NSTextField` / `TextField` focusing with `selectedRange` spanning `0..<stem.count`.
- **Address Bar Controller**:
  - Toggled by ⌘L or ⇧⌘G in toolbar/breadcrumb bar.
  - Supports autocomplete suggestions based on directory listing.
