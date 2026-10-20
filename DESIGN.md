# Shark Design System & Fidelity Specifications (DESIGN.md)

This document establishes the official design tokens, materials, interaction models, and fidelity standards for Shark, achieving parity with Apple macOS Finder while integrating the productivity powers of QTTabBar and Windows File Explorer.

---

## 1. Visual Hierarchy & Spatial Grid

Shark strictly adheres to macOS Human Interface Guidelines (HIG) with an 8pt-based spatial layout grid:

- **Window Sizing**:
  - Minimum window size: `800 × 520` pt.
  - Default initial window size: `1080 × 720` pt.
- **Sidebar**:
  - Minimum width: `170` pt.
  - Ideal width: `210` pt.
  - Maximum width: `280` pt.
  - Row height: `26` pt (compact macOS list spacing).
- **Pro Tab Strip**:
  - Height: `28` pt.
  - Pinned tab width: `40` pt (fixed).
  - Unpinned tab width: Dynamic equal-width between `120` pt and `260` pt.
- **Status Bar**:
  - Height: `22` pt.
  - Standard font: `11pt` monospaced digits.
- **Bottom Path Bar**:
  - Height: `22` pt.
  - Segment spacing: `2` pt with `8pt` chevron indicators.
- **Inspector Panel**:
  - Width: `280` pt.
  - Thumbnail preview box: `140 × 140` pt.

---

## 2. Liquid Glass Materials & Translucency

Shark delivers native macOS translucency with desktop wallpaper bleed-through across primary chrome surfaces:

| Surface | NSVisualEffectView Material | Blending Mode | Purpose |
|---|---|---|---|
| Window Backdrop | `.underWindowBackground` | `.behindWindow` | Wallpaper bleed-through behind directory panes |
| Sidebar | `.sidebar` | `.behindWindow` | Native macOS sidebar translucency |
| Unified Toolbar & Tab Strip | `.headerView` | `.withinWindow` | Vibrancy matching Safari & Finder top chrome |
| Path Bar & Status Bar | `.headerView` | `.withinWindow` | Grounded translucent base bars |
| Command Palette & Popovers | `.popover` | `.withinWindow` | Floating translucent glass cards with specular highlight |

### Specular Strokes & Separators
- Separator line: `Color(nsColor: .separatorColor)` with `0.5pt` thickness.
- Glass edge highlight: White stroke at `0.12` opacity (Dark Mode) or `0.4` opacity (Light Mode).
- Drop shadow: `Color.black.opacity(0.25)`, radius: `18`, y: `10`.

---

## 3. Typography & Micro-copy

Shark uses the macOS San Francisco system font family with tabular figures where numbers change dynamically:

| Role | Font Style | Weight | Usage |
|---|---|---|---|
| Window/Folder Title | `.system(size: 13)` | `.semibold` | Active folder name in navigation bar |
| Tab Titles | `.system(size: 12)` | `.regular` / `.medium` (active) | Tab strip items |
| List Filenames | `.system(size: 13)` | `.regular` | DetailsTableView item titles |
| Metadata Details | `.system(size: 11, design: .monospaced)` | `.regular` | File sizes, dates, permissions |
| Micro Labels | `.system(size: 9)` | `.regular` | Toolbar action captions (Path, View, Group, etc.) |
| Inspector Section Headers | `.system(size: 11, weight: .bold)` | `.bold` | "General Info", "Permissions" |

---

## 4. View Modes (Finder Parity)

1. **Icons View (⌘1)**:
   - Flexible grid with variable zoom (48pt to 192pt) via `⌘+` / `⌘-` / `⌘0` or `⌘-scroll`.
   - Two-line centered filename with middle truncation.
   - Desktop-grade drag-and-drop with spring hover opening.
2. **List View (⌘2)**:
   - High-performance `NSTableView` backing for 100,000+ files.
   - Column sorting by Name, Date Modified, Size, Kind, and POSIX Permissions.
   - Optional asynchronous folder size calculation.
3. **Miller Columns View (⌘3)**:
   - Horizontally cascading directory columns with 240pt default column width.
   - Auto-scrolling to trailing column on directory descent.
   - Leaf file preview column with large icon, quick actions (Quick Look, Open), and metadata table.
   - Full keyboard navigation (← / → switches column, ↑ / ↓ moves selection).
4. **Gallery View (⌘4)**:
   - Expansive central preview area with Quick Look integration.
   - Bottom thumbnail carousel with smooth scrolling.

---

## 5. QTTabBar & Windows Explorer Ergonomics

- **Pro Tab Strip**:
  - Middle-click to close tab.
  - Double-click empty tab strip area to open new tab (`⌘T`).
  - Pinning (`⌘P`), Tab Locking, and Tab Tint colors (Red, Orange, Yellow, Green, Blue, Purple, Gray).
  - Closed-tab stack (last 20 tabs) restored via `⇧⌘T`.
  - Tab groups: Save current tab layout by name, restore or append instantly.
- **Explorer Clipboard Operations**:
  - Cut (`⌘X`): Dims file row opacity to 45%.
  - Copy (`⌘C`): Places file URLs on macOS standard pasteboard.
  - Paste (`⌘V`): Copies files into target directory.
  - Move (`⌥⌘V`): Atomic filesystem moves with undo support.
  - Full Undo/Redo (`⌘Z` / `⇧⌘Z`) for rename, move, duplicate, and trash.
- **Subfolder Menus (QT-01 & QT-02)**:
  - Breadcrumb segment chevrons reveal cascading popover menus.
  - Subfolders open child menus on hover to arbitrary directory depths.
  - Hover previews (QT-03): Image thumbnails and text snippet popovers after a 600ms hover delay.

---

## 6. Feedback & States (POL-03)

- **Empty State**: Centered folder icon, title "This Folder is Empty", and action button "New Folder".
- **Permission Denied State**: Shield icon, title "Access Restricted", description explaining Full Disk Access requirement, and button opening System Settings directly.
- **Loading State**: Smooth indeterminate circular indicator with ease-in fade.

---

## 7. Accessibility & Motion (POL-04)

- **VoiceOver**: All buttons, tabs, split containers, breadcrumb buttons, and view pickers provide explicit `.accessibilityLabel` and `.accessibilityHint`.
- **Reduced Motion**: Respects `@Environment(\.accessibilityReduceMotion)`, replacing spring zoom animations with direct opacity crossfades.
