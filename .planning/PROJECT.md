# Shark — Finder-look File Manager with QTTabBar & Explorer Power

## What This Is

Shark is an ultra-fast, native macOS clone of KDE's renowned Dolphin file manager. Built from the ground up with Swift 6, SwiftUI, and AppKit, Shark brings Dolphin's beloved power-user paradigms — dual-pane split navigation (F3), an integrated interactive terminal drawer (F4), an instant metadata and preview inspector (F11), editable breadcrumb navigation, fast filtering (Cmd+I), tabs, and asynchronous file operations — to the macOS desktop with native feel and performance.

## Current Milestone: v2.0 Finder Look, QTTabBar Power

**Goal:** Keep the native Finder look and add QTTabBar-grade tabs and folder navigation, Explorer ergonomics, and a command palette.

**Target features:** pro tabs + session restore, cut/copy/paste + undo, cascading subfolder menus + hover previews, ⌘K palette + full menus, Finder fidelity polish.

## Core Value

Bring KDE Dolphin's dual-pane, terminal-integrated, and keyboard-centric file management workflow to macOS users as a high-performance native application.

## Requirements

### Validated

(None yet — greenfield project initialization)

### Active

- [ ] **Dual-Pane Split View (F3)**: Side-by-side or stacked independent file browsers with active pane tracking, drag-and-drop, and synchronized navigation options.
- [ ] **Tabbed Browsing**: Seamless multi-tab management (Cmd+T, Cmd+W) retaining individual pane layouts, paths, and view modes per tab.
- [ ] **Multiple View Modes**: High-performance Grid/Icons view (with zoomable thumbnails), Details/Table view (with sorting by name, size, date, permissions, expandable folders), and Compact list view.
- [ ] **Interactive Breadcrumb & Location Bar**: Clickable path breadcrumbs for fast parent directory jumping, switchable to an editable text bar for direct path input with auto-completion and tilde expansion.
- [ ] **Places Sidebar**: Quick navigation to System Volumes, User directories (Home, Desktop, Downloads, Documents), pinned Favorites, and Trash.
- [ ] **Embedded Terminal Drawer (F4)**: Dockable bottom terminal panel powered by an interactive pseudo-terminal (PTY) running the user's login shell (zsh/bash), automatically synchronized to the active pane's directory.
- [ ] **Metadata & Preview Inspector (F11)**: Right-hand inspector displaying rich metadata (POSIX permissions, MIME types, file sizes, image dimensions, audio/video duration) and live previews.
- [ ] **Instant Filter Bar (Cmd+I)**: Dolphin-style instantaneous in-memory search/filter bar for current directory contents.
- [ ] **Asynchronous File Operations Engine**: Non-blocking copy, move, duplicate, trash, delete, rename, batch rename, and new folder/file creation with progress, cancellation, and collision handling.
- [ ] **Live Filesystem Monitoring**: Real-time directory refresh powered by macOS `FSEvents` so external file changes reflect immediately.
- [ ] **macOS System Polish**: Full Quick Look integration (Spacebar), drag-and-drop with Finder and cross-pane, context menus, and keyboard shortcuts matching both Dolphin and Mac expectations.

### Out of Scope

- Remote protocols (KIO slaves like sftp/fish/smb) in v1 — local filesystems and mounted volumes will be prioritized for v1 performance.
- Direct KDE/Qt C++ dependencies — completely native Swift implementation without Qt or C++ wrappers.
- Cloud storage proprietary sync APIs (Dropbox, Google Drive API wrappers) — relying on standard local volume mounts and Finder-synced folders.

## Context

- Target OS: macOS 14.0+ (Sonoma) and macOS 15.0+ (Sequoia).
- Language: Swift 6 (Strict Concurrency).
- UI Framework: SwiftUI supplemented by AppKit (`NSViewRepresentable` / `NSViewControllerRepresentable`) for high-performance table views, terminal PTY hosting, and QuickLook (`QLPreviewPanel`).
- Architecture: Modern `@Observable` state management, actor-isolated file operations, and decoupled modular components.

## Constraints

- **Tech Stack**: Pure Swift 6, SwiftUI, AppKit, Foundation, CoreServices (FSEvents), QuickLook.
- **Performance**: Instantaneous browsing of directories with 100,000+ files without UI hitching; non-blocking background operations.
- **Safety**: Safe handling of file deletions and moves (preferring `FileManager.trashItem` with permanent delete safeguards).

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Pure Swift & SwiftUI/AppKit | Maximizes performance, responsiveness, macOS look-and-feel, and removes heavy Qt/C++ runtime overhead. | — Pending |
| Swift 6 Concurrency & Actor-Isolated File Operations | Guarantees data-race safety and keeps UI thread at a silky smooth 60/120fps during large copy/move tasks. | — Pending |
| Native PTY Terminal Integration | Embeds actual interactive zsh shell like Dolphin F4 rather than a simple command runner. | — Pending |
| FSEvents for Directory Observation | Zero-overhead, battery-efficient live synchronization with external file system changes. | — Pending |

---
*Last updated: 2026-10-13 after project initialization*
