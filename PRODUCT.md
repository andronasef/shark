# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

Native macOS desktop app (not one of web/ios/android/adaptive). Swift 6, SwiftUI with AppKit bridges. macOS 14+.

## Users

Power users on a Mac remain the primary audience: developers, designers, and people coming from Windows or KDE who jump between project folders, copy between locations, open terminals in folders, and want every action one keystroke away. Everyday Mac users moving off Finder are a second audience. Matching Finder's everyday capabilities is the minimum; power features build on that familiar base.

## Product Purpose

Shark is a file manager for macOS that combines three things: the depth of QTTabBar (pro tabs, subfolder menus, hover previews, a command for everything), the ease of Windows File Explorer (address bar, Cut/Paste, status bar, details pane, nothing hidden), and Dolphin's power layout (split panes F3, terminal drawer F4, inspector F11, instant filter). Success means a user can drop Finder for daily work.

## Positioning

Finder hides things and Explorer has no taste. Shark is dense and fast like a power tool, and it is plain enough that a first-time user finds every action without reading docs.

## Operating Context

Long sessions in a window that stays open all day, often beside an editor and a terminal. Keyboard-heavy, but mouse users must never hit a dead end. Directories range from empty to 100k+ entries. Local disks and mounted volumes only.

## Capabilities and Constraints

- Shipped: pro tabs with session restore, dual pane, four view modes, instant filter, Quick Look, PTY terminal drawer (SwiftTerm), inspector with checksums, async file ops, batch rename, FSEvents, drag and drop, cascading subfolder menus, hover previews, command palette, Cut/Paste and undo, copy path, calculated folder sizes, and a rich status bar. The website feature catalog is the complete public inventory.
- In scope next: all three groups in `ROADMAP.md`: everyday essentials (safe collision choices, extraction, Trash, extension warnings, iCloud, search and real Finder tags); expected Mac workflows (Recents, places, transfer controls, aliases, spring loading, Get Info, server mounting); and Quick Actions, grouping, saved searches, AirDrop, Print and Services. Planned features become public claims only after implementation and verification.
- Constraints: pure Swift/SwiftUI/AppKit, no Qt/C++, trash before delete, never block the main thread.
- Remote connections are mounted by macOS and then browsed as ordinary mounted volumes. Connect to Server hands supported addresses to macOS; Shark does not implement SMB, AFP, NFS, SFTP, or other remote protocol stacks.
- Out of scope: proprietary cloud provider APIs and replacing other applications' system Open/Save dialogs. Native iCloud file metadata and download APIs are in scope.

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
6. Match Finder's everyday workflows before adding new power features; explain system handoffs and limitations plainly.

## Accessibility & Inclusion

Full keyboard operation, VoiceOver labels on all controls, respect Reduce Motion and Increase Contrast, follow system light/dark.
