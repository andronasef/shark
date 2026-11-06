# Phase 9: UI Specification — QTTabBar Folder Power

## 1. Visual Hierarchy & Philosophy
- Respect macOS Human Interface Guidelines and `$impeccable` styling.
- Breadcrumbs retain their crisp Finder feel, augmented by subtle disclosure arrows that trigger rich native cascading `NSMenu`s.
- Hover previews appear unobtrusively in a floating translucent card adjacent to the hovered item, fading in smoothly and dismissing immediately when the cursor departs.

## 2. Component Specifications

### A. Cascading Subfolder Menu (Breadcrumbs & Folders)
- **Trigger**:
  - Breadcrumb segment: A subtle disclosure chevron (`chevron.down`, size 8pt) next to each folder name in both top breadcrumb bar and bottom path bar.
  - Row / Grid item: Context menu item "Browse Subfolders ▸", and an optional hover arrow icon on folder rows.
- **Menu Behavior**:
  - Populates child directories first (with folder icons), followed by child files (with system file icons).
  - Child folders have submenu arrows (`▸`) that dynamically expand to show their contents recursively on hover.
  - Clicking any folder item navigates the current pane to that folder.
  - ⌘-Clicking any folder item opens it in a new tab.
  - Clicking any file opens it using the default system application (`NSWorkspace.shared.open(url)`).
  - Empty directories show a disabled `(Empty)` menu item.

### B. Hover QuickPreview Popover
- **Trigger**:
  - Hovering on any file row or grid cell for ≥ 350ms without moving the mouse away.
- **Visual Presentation**:
  - Window style: Floating borderless panel with `.behindWindowBlends` or SwiftUI popover with `.ultraThinMaterial`.
  - Corner radius: 10pt.
  - Border: 1pt stroke of `Color.primary.opacity(0.12)`.
  - Shadow: Soft macOS system drop shadow (`radius: 8, y: 4`).
- **Content Types**:
  - **Images** (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.heic`, `.svg`): High-res thumbnail scaled aspect-fit, max 320x240 pt, with filename and resolution/size subtitle.
  - **Text / Code / Markdown** (`.txt`, `.swift`, `.json`, `.md`, `.py`, `.js`, etc.): First 12 lines of text in a monospaced font (11pt), background slightly darkened, line count indicator.
  - **PDFs**: First page thumbnail preview.
- **Dismissal**:
  - Mouse moves outside the bounding box of the source row or moves across rows.
  - Key press (Escape or arrow keys).

### C. Recent & Frequent Folders in Sidebar
- **Sidebar Integration**:
  - Under "Favorites" and "Locations", add collapsible sections:
    - `Recent Folders`: Top 10 most recently accessed directories.
    - `Frequent Folders`: Top 5 most frequently visited folders (visit count ≥ 3).
  - Each item shows the folder icon, folder name, and full path in its tooltip.
  - Right-click offers "Open in New Tab", "Open in Split Pane", "Copy Path", and "Remove from Recents".

### D. Tab Groups
- **Trigger & UI**:
  - Tab Strip trailing button or Tab menu: "Save Current Tabs as Group...".
  - Dialog or inline popover prompting for a group name (e.g. "Work", "Personal", "Code").
  - Menus and Sidebar expose saved Tab Groups. Clicking a group opens all its tabs.
  - Context menu on a Tab Group: "Open in New Window", "Replace Tabs", "Append Tabs", "Delete Group".
