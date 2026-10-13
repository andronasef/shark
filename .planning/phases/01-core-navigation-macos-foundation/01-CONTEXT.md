# Phase 1: Core Navigation & macOS Foundation - Context

**Gathered:** 2026-10-13
**Status:** Ready for planning
**Mode:** Autonomous (Dolphin macOS Clone Core)

<domain>
## Phase Boundary

Establish the native macOS application foundation using Swift 6 and SwiftUI + AppKit.
Deliver single-pane directory navigation, high-performance asynchronous file listing, clickable/editable breadcrumbs location bar, Places sidebar (System Volumes, User folders, Trash, and Favorites), and history navigation (Back, Forward, Up).

Requirements covered: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05.
</domain>

<decisions>
## Implementation Decisions

### 1. Technology & Project Structure
- Pure Swift Package Manager (SPM) executable target + macOS App bundle capability (`Package.swift`).
- Swift 6 language mode with strict concurrency checking.
- Target macOS 14+ (Sonoma) / macOS 15+ (Sequoia).
- UI built with SwiftUI lifecycle `App` with `WindowGroup`, `NavigationSplitView`, modern toolbar controls, and AppKit bridges where needed.

### 2. Architecture & Concurrency
- `FileSystemService`: Actor-isolated or async-safe file system access utilizing `FileManager`, `URLResourceKey`, and asynchronous directory stream enumeration for maximum performance on large directories.
- `FileItem`: Value type representing a filesystem node (name, url, isDirectory, isPackage, isHidden, isSymlink, fileSize, dateModified, kindDescription, systemIcon).
- `@Observable` NavigationState / PaneState: Reactive state tracking current path, history stack (back/forward), path input mode, selected items, and sorting.

### 3. Navigation & Breadcrumb Bar
- Segmented clickable breadcrumb bar: Each ancestor segment is a button that navigates directly to that folder.
- Direct path input toggle (`Cmd+L`): Smoothly switches between breadcrumb buttons and an editable `NSTextField`/`TextField` with path completion and `~` expansion.
- History back/forward navigation (`Cmd+[` / `Cmd+]`) and parent directory jump (`Cmd+Up`).

### 4. Places Sidebar
- Standard macOS Places sections:
  - System: Root Volume (`/`), mounted volumes (`/Volumes/*`).
  - Favorites / User: Home (`~`), Desktop, Documents, Downloads, Applications.
  - Trash (`~/.Trash`).
- Pinned custom locations with add/remove support.

</decisions>

<code_context>
## Existing Code Insights

Greenfield phase. Clean slate with modern Swift 6 patterns.
</code_context>
