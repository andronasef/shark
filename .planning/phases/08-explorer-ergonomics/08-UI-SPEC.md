# Phase 8: UI Design Specification (Explorer Ergonomics)

## Visual Hierarchy & Styling Rules

### 1. Cut Items Dimming (Explorer Standard)
- Cut items in list, grid, and column views rendered at `opacity(0.45)` with subtle saturation reduction.
- Cleared as soon as paste occurs, or new selection is cut, or Escape is pressed.

### 2. Inline Rename Field
- Activated via Return key on single selection.
- Text selection: `0..<stem.count` (extension unselected).
- Styling:
  - Height: 20pt (in list/details), matches cell height.
  - Border: 1.5pt solid `Color.accentColor` with 3pt corner radius.
  - Background: `Color(nsColor: .controlBackgroundColor)`.
  - Font: 12pt regular (matches item text).
- Keyboard:
  - `Return` / `Enter`: commits change.
  - `Escape`: cancels rename and reverts text.
  - Clicking outside: commits change.

### 3. Rich Status Bar & Bottom Path Bar
- Layout:
  - Height: 22pt flush at bottom of DirectoryView.
  - Background: `Color(nsColor: .windowBackgroundColor).opacity(0.7)` with 0.5pt top separator border `Color(nsColor: .separatorColor)`.
  - Left segment:
    - Text: e.g. `24 items, 3 selected (14.2 MB)` or `24 items` when none selected.
    - Font: 11pt Regular, `Color.secondary`.
  - Center/Right segment:
    - Available disk space: `184.2 GB available`.
    - Progress spinner & progress bar when background operation is active, plus `xmark.circle.fill` cancel button.
    - Zoom slider preserved in Grid mode.
- Bottom Path Bar (Finder style, toggleable with ⌥⌘P or View menu):
  - Height: 20pt directly above or integrated in the bottom bar.
  - Breadcrumbs with folder icons: `Macintosh HD › Users › andrew › Projects › shark`.
  - Double-clicking any ancestor navigates there; ⌘-clicking opens it in a new tab; right-clicking opens context menu.

### 4. Forgiving Address Bar (⌘L / ⇧⌘G)
- Mode toggle:
  - Pressing ⌘L or clicking the breadcrumb title area switches the header to an inline Address Input field.
  - Focus is immediate, full text selected.
  - Tab performs path completion.
  - Left accessory icon: folder / drive icon.
  - Right accessory: Clear button (X) when non-empty.
  - On Enter: validates path; if valid navigates immediately and reverts to breadcrumbs. If invalid: shakes subtly and displays red outline + tooltip "Folder does not exist" without losing current directory.
  - On Escape: discards input and reverts to breadcrumb title.

### 5. Extended Context Menu
- Additions to FileItem context menu:
  - Open in New Tab (existing)
  - Open in Terminal
  - Open With... (submenu with default application & other registered handlers)
  - Quick Look (Space)
  - Show in Finder
  - ───
  - Cut (⌘X)
  - Copy (⌘C)
  - Paste (⌘V) [in background / folder]
  - ───
  - Rename (Enter)
  - Duplicate (⌘D)
  - Compress "[Name]" (creates zip)
  - ───
  - Copy Path (⌥⌘C)
    - Copy Full Path
    - Copy Relative Path
    - Copy POSIX Quoted Path
  - ───
  - Calculate Size (for directories)
  - Move to Trash (⌘⌫)
