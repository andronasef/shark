# Phase 3: View Modes, Instant Filtering & Quick Look - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin Multi-View Modes, Filtering, and Quick Look)

<domain>
## Phase Boundary

Deliver advanced view customization matching KDE Dolphin:
1. Three distinct view modes: Details (multi-column sortable table), Grid/Icons (with dynamic zoom slider and system thumbnail generation), and Compact list.
2. Dolphin's signature Instant Filter bar (Cmd+I) with real-time filtering.
3. Native macOS Quick Look integration (Space key) using `QLPreviewPanel` to inspect any selected document, photo, video, or audio file.

Requirements covered: VIEW-01, VIEW-02, VIEW-03, VIEW-04, VIEW-05.
</domain>

<decisions>
## Implementation Decisions

### 1. View Modes
- Details View: Table with sortable column headers (Name, Size, Modified Date, Kind, Permissions), clicking a column header toggles sort ascending/descending.
- Grid View: Adaptive grid with zoom control (48pt to 192pt) via a bottom status slider or keyboard shortcut.
- Compact View: Multi-row compact list view for high-density browsing.

### 2. Live Thumbnail Generation
- `ThumbnailService`: Generates live asynchronous thumbnails using `QLThumbnailGenerator` and caches them in an `NSCache` memory cache with fallback to system icon (`NSWorkspace.shared.icon(forFile:)`).

### 3. Instant Filter Bar (Cmd+I)
- Embedded header filter bar:
  - Input field focused upon `Cmd+I`.
  - Filters `filteredAndSortedItems` instantly without disk I/O.
  - Matches case-insensitively against name, extension, and kind description.
  - Filter badge showing "X of Y items".

### 4. Native Quick Look Integration (Spacebar)
- `QuickLookCoordinator`: Subclass of `NSResponder` / `QLPreviewPanelDataSource` and `QLPreviewPanelDelegate` that responds to the `Space` key or Quick Look action.
- When `Space` is pressed on a selected file, the shared `QLPreviewPanel` is displayed with the file's URL.

</decisions>
