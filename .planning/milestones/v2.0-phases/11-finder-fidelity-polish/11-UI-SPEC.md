# Phase 11: Finder Fidelity Polish & Liquid Glass - UI Spec

## Visual Design & System Specs

### 1. Liquid Glass Translucency & Materials (POL-06)
- **Window Backdrop**: Native `NSVisualEffectView` with `.behindWindow` blending mode and `.underWindowBackground` / `.windowBackground` material, allowing wallpaper translucency.
- **Sidebar**: Native `.sidebar` material with thin border separator (`Divider().opacity(0.35)`).
- **Tab Strip & Unified Toolbar**: Subtle liquid glass material overlay (`.headerView` material) with specular top highlight border (`Color.white.opacity(0.12)` in dark mode, `Color.white.opacity(0.4)` in light mode).
- **Floating Modals & Cards**: `LiquidGlassView` with subtle inner specular stroke and deep drop shadow (`Color.black.opacity(0.25)`, radius: 18, y: 10).

### 2. Real Miller Columns View (POL-02)
- **Layout**: Horizontal `ScrollView` containing an ordered array of `ColumnPane`s:
  - Column 0: Root active directory.
  - Column 1..N: Subdirectory levels selected by the user.
  - Final Column: If a file is selected in the deepest column, display an Inspector / Preview column (file icon/thumbnail, name, kind, size, creation date, modification date, Quick Look trigger, Open action).
- **Column Styling**: Fixed/resizable width (default 240pt), vertical divider separator, smooth scrolling to trailing edge when a column is expanded.
- **Item Row**: 16pt icon + item name + right-pointing chevron `›` if directory. Accent color fill when selected.
- **Keyboard Navigation**:
  - `↑` / `↓`: Move selection in current column.
  - `→`: Enter selected directory (opens next column to the right).
  - `←`: Navigate back to parent column.

### 3. States & Feedback (POL-03)
- **Empty State**: Centered SF Symbol (`folder` with dashed stroke or `tray`), title "This folder is empty", subtitle "Drag and drop items here, or press ⇧⌘N to create a new folder".
- **Permission Denied State**: SF Symbol `lock.shield`, title "Access Restricted", explanation "Shark needs permission to browse this location", button "Open System Settings" (invoking `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`).
- **Loading State**: Subtle centered circular `ProgressView` with ease-in appearance.

### 4. Accessibility & Motion (POL-04)
- All buttons and controls have explicit `.accessibilityLabel` and `.accessibilityHint`.
- `reduceMotion` environment flag gates spring transitions into instant opacity swaps.
