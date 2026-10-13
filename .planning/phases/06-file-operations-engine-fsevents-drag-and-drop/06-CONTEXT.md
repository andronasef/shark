# Phase 6: File Operations Engine, FSEvents & Drag-and-Drop - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin File Operations Engine)

<domain>
## Phase Boundary

Deliver KDE Dolphin's file management muscle:
1. High-performance asynchronous non-blocking file operations engine:
   - Copy, Move, Duplicate, Trash, Delete
   - Create New Folder (`⇧⌘N`) and Create New File
   - Batch Rename dialog with regex / find-and-replace / numbered indexing
2. Real-time file system monitoring via macOS CoreServices `FSEvents` so external changes (terminal edits, downloads, git branch switches) immediately reflect without manual reload.
3. Native drag-and-drop: dragging files between dual panes, to/from Finder, and to sidebar destinations.

Requirements covered: OPS-01, OPS-02, OPS-03, OPS-04, OPS-05.
</domain>

<decisions>
## Implementation Decisions

### 1. FileOperationsService (Actor)
- Handles async I/O off the main thread:
  - `copy(items: [URL], to: URL)`
  - `move(items: [URL], to: URL)`
  - `duplicate(items: [URL])`
  - `trash(items: [URL])`
  - `deletePermanently(items: [URL])`
  - `createFolder(named: String, at: URL)`
  - `createFile(named: String, at: URL)`
  - `batchRename(items: [URL], rule: RenameRule)`

### 2. Live FSEventsWatcher
- Uses macOS `FSEventStreamCreate` on the active directory path.
- Debounces events (e.g. 100ms latency) and triggers an async callback to `NavigationState.reloadCurrentDirectory()` whenever file system changes occur.

### 3. Batch Rename Sheet
- `BatchRenameSheet`: Displays original names alongside real-time preview of transformed names based on:
  - Text replacement (find & replace)
  - Prefix / Suffix addition
  - Sequential numbering (`file_01.ext`, `file_02.ext`)

### 4. Drag and Drop
- SwiftUI `.draggable()` supplying URLs via `Transferable` / `NSItemProvider`.
- SwiftUI `.dropDestination(for: URL.self)` on directory panes and sidebar items handling copy/move with Option key detection.

</decisions>
