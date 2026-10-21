# Shark Design System & Fidelity Specifications (DESIGN.md)

This document establishes the official design tokens, materials, interaction models, and fidelity standards for Shark, achieving parity with Apple macOS Finder while integrating the productivity powers of QTTabBar and Windows File Explorer.

The Astro marketing website has its own responsive layout and web material rules in [`website/DESIGN.md`](website/DESIGN.md); this document continues to govern the native macOS application.

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
  - Row height: `32` pt, with `14` pt labels and `22` pt icon slots.
  - Inset panel: `20` pt continuous corners, `6` pt horizontal inset, adaptive material with a subtle blue-to-neutral outline.
  - Section headings: `12` pt semibold in a full-width `26` pt hit area, with `14` pt top spacing, hover feedback, and a separate keyboard focus outline.
  - Expansion, keyboard focus, and folder selection are independent. Headings support Space/Return and Left/Right; Up/Down moves focus among visible sidebar controls. Collapsing moves child focus to the heading and retains folder selection. Expansion is persisted; Reduce Motion disables the 180 ms transition.
  - Sidebar folder navigation and exact-match selection follow the active pane. Favorites containing the current folder show a subtle dot instead of a selected fill.
  - Favorites are persistent, user-selected folder shortcuts. Add/reorder insertion targets are distinct from folder destinations; internal shortcut drags cannot move files. Removal leaves folders intact. Unavailable targets retain their labels and offer relocation.
  - Dragging over a collapsed section temporarily expands it after 600 ms; leaving or ending the drag restores temporary state. A successful drop onto Favorites persists expansion.
- **Pro Tab Strip**:
  - Height: `34` pt, with `28` pt tab capsules, `12` pt labels, and `20` pt close-button slots.
  - Open/close motion: `200ms` ease-out, subtle `0.96` scale and fade, with animated width redistribution. Reduce Motion disables movement.
  - Pinned tab width: `40` pt (fixed).
  - Unpinned tabs share the entire available width equally, with a `120` pt minimum and horizontal scrolling when needed. Centered text labels omit folder icons; the circular add button stays at the trailing edge.
- **Status Bar**:
  - Height: `22` pt.
  - Standard font: `11pt` monospaced digits.
- **Toolbar Path Bar**:
  - Located beside Back/Forward in a `28` pt glass capsule, showing the active pane’s path. Navigation and Location share one native toolbar item with an `8` pt gap, keeping their order and placement together during launch and window restoration.
  - Ancestors support navigation and subfolder menus; `⌘L` edits the path.
  - The capsule starts directly beside Navigation and fills all remaining toolbar width (minimum `160` pt), so long paths stay readable. Toolbar items do not stretch on their own, so its width is the detail-column width minus a fixed allowance for the other items (`otherToolbarItemsWidth = 768` pt in `ContentView.swift`); add `collapsedSidebarInset = 116` pt when the sidebar is hidden (traffic lights join the toolbar row); retune both when toolbar items change. Breadcrumb separators are 7 pt medium chevrons in the tertiary label colour; only the current segment is emphasised (semibold on a neutral capsule, no tinted icon). One menu chevron per segment and a neutral current-folder highlight keep the path compact.
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

### Native toolbar and tab chrome (macOS 26+)

- `FinderChromeView.swift` applies SwiftUI `glassEffect(_:in:)` to custom capsule groups and `GlassEffectContainer` to adjacent tab-strip surfaces. Native toolbar shared backgrounds are hidden for those items to avoid duplicate glass.
- Controls are 28 pt high, with 9 pt captions below; the four view modes share one capsule with an adaptive selection highlight. Search uses a 200 pt wide capsule.
- The translucency preference, Reduce Transparency, and increased contrast select semantic opaque fills for this custom chrome. macOS 14/15 use thin material instead of native glass.
- Back, Forward, and Up share a glass navigation capsule; Split and Terminal have matching glass toolbar buttons with active-state highlights. Existing shortcuts and menu actions remain available. Tab Groups are also available by right-clicking the add button.
- The legacy material table above describes the remaining visual-effect wrappers; those are vibrancy, distinct from native Liquid Glass.

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
  - Paste (`⌘V`): Copies files into the target directory, or moves them after a Cut. Never overwrites: copies take a "name copy N" name, a move onto an existing name (case-insensitive) is refused, and pasting a cut back into its own folder does nothing.
  - Drop: moves within a volume, copies across volumes (Finder rule). `⌥` forces copy, `⌘` forces move. Never into the item itself or a descendant.
  - Multi-item operations are all-or-nothing: a failure part-way rolls back the finished items. Failures show an alert; they are never silent.
  - Compress: one archive operation per pane; the status bar Stop button cancels it and removes its private partial output. Only a finished ZIP appears in the folder.
  - Full Undo/Redo (`⌘Z` / `⇧⌘Z`) for every file operation: move, copy, duplicate, new item, rename, batch rename, compress, and trash. Undoing something Shark created moves it to the Trash, never deletes it.
  - With a text field or the terminal focused, the Edit-menu shortcuts (`⌘X` `⌘C` `⌘V` `⌘A` `⌘Z` `⌘⌫`) edit text, not files.
- **Subfolder Menus (QT-01 & QT-02)**:
  - Breadcrumb segment chevrons reveal cascading popover menus.
  - Subfolders open child menus on hover to arbitrary directory depths.
  - Mouse zones: empty folder space (double-click = up), item, tab (double-click = pin, middle-click = close), tab strip (wheel = switch tab), sidebar/path bar, anywhere (side buttons = back/forward). The Help window lists them all; keep it in sync.
  - Subfolder tip: a circular drop-down arrow on a material fill with a hairline border appears when a folder is hovered: `20` pt beside the name in the list, `26` pt in the top-right corner of the cell in the icon view and opens the cascading menu; ⌘-click opens in a new tab, ⌥-click copies. Toggle in Settings › Previews.
  - Hover previews (QT-03): a non-activating floating panel beside the pointer (never steals focus) after a configurable delay, optionally only while holding Shift. Shows full-resolution and animated images, up to 40 lines of text (UTF-8/UTF-16/Latin-1, binary rejected), document thumbnails, and inline video/audio players with a seek bar. The pointer can move into the panel to use the controls.

---

## 6. Feedback & States (POL-03)

- **Feature discovery**: The welcome’s feature step uses `16` pt row spacing, explains that Help › All Features opens the complete website catalog, and offers a direct View All Features link. Shark Help repeats the link above its mouse reference; the website remains the single public feature inventory.
- **First-run welcome**: A native `580 × 560` pt sheet appears once after the main window is ready: Welcome, essential features, then optional setup. Use a `72` pt app icon, `26` pt bold heading, `32` pt content insets, a scrollable body, and a fixed footer with Back, step count, Skip Setup, and Continue / Start Using Shark. Native controls, system colors, and no authored transition animation. Dismissing consumes the automatic offer; Help › Welcome to Shark reopens it. Already-default users still see the introduction, with the default-app action disabled.
- **Folder integration**: Default-folder-app status comes from macOS and refreshes on activation. Changes require an explicit button press and system consent where requested; controls disable during the request. Verify the actual association before showing success. If the modern API rejects the folder type with `paramErr (-50)`, use the public Launch Services folder handler API; never fall back after denied consent. General settings offer Make Shark Default and Restore Finder. When both APIs reject folder changes, show a truthful unchanged status and Manual Setup: a native `560` pt wide sheet with `28` pt padding, separate copyable Shark/Finder commands, and explicit restart/compatibility guidance. Never execute these commands, change `NSFileViewer`, or claim pending preferences are active. The welcome’s setup page and Privacy settings offer a Full Disk Access settings link with manual instructions; access is optional, never auto-granted, and never marked granted just because Settings opened.
- **External folder opening**: Reuse a matching visible pane, otherwise append/select a new tab. Resolve symbolic links for matching; preserve locked tabs and existing sessions. Reopen the main window if closed. Unsupported URLs, files, missing folders, and packages report an error. Folder defaults do not replace Finder-specific reveal commands or system file dialogs.
- **Empty State**: Centered folder icon, title "This Folder is Empty", and action button "New Folder".
- **Permission Denied State**: Shield icon, title "Access Restricted", description explaining Full Disk Access requirement, and button opening System Settings directly.
- **Loading State**: Smooth indeterminate circular indicator with ease-in fade.

---

## 7. Accessibility & Motion (POL-04)

- **VoiceOver**: All buttons, tabs, split containers, breadcrumb buttons, and view pickers provide explicit `.accessibilityLabel` and `.accessibilityHint`.
- **Reduced Motion**: Respects `@Environment(\.accessibilityReduceMotion)`, replacing spring zoom animations with direct opacity crossfades.
