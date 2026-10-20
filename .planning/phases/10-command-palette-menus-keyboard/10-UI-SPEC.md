# Phase 10: UI Specification — Command Palette, Menus & Keyboard

## 1. Command Palette (⌘K / ⇧⌘P)
- **Position & Geometry**:
  - Centered horizontally, pinned 12% from top of window.
  - Width: 560pt, max height: 420pt.
  - Border radius: 14pt with subtle 1pt border (`Color.primary.opacity(0.15)`).
  - Material: Liquid Glass backdrop (`NSVisualEffectView` with `.popover` material) + soft system shadow.
- **Search Header**:
  - Magnifying glass icon (16pt, `.secondary`).
  - Native NSTextField or SwiftUI TextField with `placeholder = "Type a command, folder, or path..."`.
  - Esc badge (`esc`) on trailing edge to dismiss.
- **Results List**:
  - Categorized sections:
    - *Actions* (Split view, Terminal, Inspector, Quick Look, Copy Path, Compress, etc.)
    - *Navigation* (Home, Desktop, Downloads, Documents, Volumes)
    - *Recent & Frequent Folders*
    - *Tab Groups*
    - *Go to Path* (when query starts with `/` or `~`)
  - Highlighted item: accented background (`Color.accentColor.opacity(0.18)`), high-contrast text.
  - Trailing shortcut badge showing keyboard shortcut (e.g. `⌘K`, `F3`, `⌥⌘P`).
- **Interaction**:
  - `↑` / `↓` moves active highlight.
  - `Return` triggers the action and closes the palette.
  - `Escape` closes the palette without action.
  - Clicking outside closes the palette.

## 2. Type-to-Select
- In any active pane (Details Table or Icons Grid):
  - Typing alphanumeric characters immediately focuses search buffer.
  - Matches first item whose filename starts with (or contains) typed string (case-insensitive).
  - Selects matching item, scrolls it into view.
  - Auto-resets typing buffer after 800ms of inactivity.

## 3. Keyboard Invariants
- `⌘↓`: Open selected folder (navigates active pane) or open file with default app.
- `⌘↑`: Navigate active pane to parent/enclosing folder.
- `Return`: Start inline rename of selected item (with stem selected).
- `Space`: Quick Look preview of selected item(s).
- `F3`: Toggle Split View.
- `F4`: Toggle Terminal Drawer.
- `F11`: Toggle Inspector Panel.

## 4. Settings Window (⌘,)
- Standard macOS Settings panel (`Settings` scene or `.sheet(isPresented:)` if fallback).
- Tab 1: General (Default View Mode, Startup Path, Show Hidden Files).
- Tab 2: Tabs (New tab placement, Restore session on startup).
- Tab 3: Previews (Hover quick-preview toggle, delay duration slider).
- Follows `$impeccable` layout: aligned form rows, native macOS toggles and pickers.
