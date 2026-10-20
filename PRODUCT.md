# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

Native macOS desktop app (not one of web/ios/android/adaptive). Swift 6, SwiftUI with AppKit bridges. macOS 14+.

## Users

Power users on a Mac who manage many files every day (developers, designers, people coming from Windows or KDE) and find Finder slow for real work. They jump between project folders, copy between locations, open terminals in folders, and want everything one keystroke away. *(Inferred from the brief and repo; confirm.)*

## Product Purpose

Shark is a file manager for macOS that combines three things: the depth of QTTabBar (pro tabs, subfolder menus, hover previews, a command for everything), the ease of Windows File Explorer (address bar, Cut/Paste, status bar, details pane, nothing hidden), and Dolphin's power layout (split panes F3, terminal drawer F4, inspector F11, instant filter). Success means a user can drop Finder for daily work.

## Positioning

Finder hides things and Explorer has no taste. Shark is dense and fast like a power tool, and it is plain enough that a first-time user finds every action without reading docs.

## Operating Context

Long sessions in a window that stays open all day, often beside an editor and a terminal. Keyboard-heavy, but mouse users must never hit a dead end. Directories range from empty to 100k+ entries. Local disks and mounted volumes only.

## Capabilities and Constraints

- Shipped: tabs, dual pane, four view modes, instant filter, Quick Look, PTY terminal drawer (SwiftTerm), inspector with checksums, async file ops, batch rename, FSEvents, drag and drop.
- In scope next: tab pro features (reorder, pin/lock, reopen closed, session restore, middle-click close), subfolder hover menus and previews, a command palette with recent/frequent folders, and Explorer ergonomics (Cut/Paste, copy path, folder size, rich status bar, show hidden).
- Constraints: pure Swift/SwiftUI/AppKit, no Qt/C++, trash before delete, never block the main thread.
- Out of scope: remote protocols (sftp/smb), cloud provider APIs.

## Brand Commitments

The name is "Shark". **Standing preference (user, 2026-10-20): Shark looks like native macOS Finder.** The power comes from QTTabBar and Windows File Explorer, not from a new visual identity. Peer products that set the craft bar: macOS Finder (look), QTTabBar (tab and folder power), Windows 11 File Explorer (ease, discoverability). Use system materials, SF Pro, SF Symbols and the system accent colour; add no custom brand palette.

## Evidence on Hand

No testimonials, benchmarks, or users to cite. Do not invent any.

## Product Principles

1. Every action is findable by eye and doable by key.
2. Density with calm: show more, but never shout.
3. Nothing destructive without an undo or the Trash.
4. Speed is a feature; the UI never waits on the disk.
5. Explorer-familiar where habit helps, Shark-specific where it earns it.

## Accessibility & Inclusion

Full keyboard operation, VoiceOver labels on all controls, respect Reduce Motion and Increase Contrast, follow system light/dark.
