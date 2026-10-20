# Phase 10: Command Palette, Menus & Keyboard — Context

## Goal
Deliver a unified, keyboard-first, discoverable workflow matching both macOS Finder fidelity and power-user tooling (VSCode/Raycast/QTTabBar):
1. **Command Palette (⌘K / ⇧⌘P)**:
   - Spotlight/Raycast-style floating palette with Liquid Glass backdrop.
   - Fuzzy search over all application commands, open tabs, recent/frequent folders, favorites, tab groups, and direct filesystem paths.
   - Arrow-key selection and Enter to execute or navigate.
2. **Complete Native Menu Bar (File, Edit, View, Go, Tab, Window, Help)**:
   - Full keyboard shortcuts for every capability:
     - F3: Split View
     - F4: Terminal Drawer
     - F11: Inspector Panel
     - Space: Quick Look
     - ⌘1..4: View Modes
     - ⌘K / ⇧⌘P: Command Palette
     - ⌘, : Preferences / Settings
     - ⌘↓: Open item
     - ⌘↑: Go to enclosing folder
3. **Type-to-Select & Explorer Navigation**:
   - Quick search / jump as you type in Details and Grid views.
   - Buffer timeout (800ms) with prefix and fuzzy matching, automatic row/item selection, and scrolling into view.
   - ⌘↓ to enter directory or open file; ⌘↑ to navigate to enclosing folder.
4. **Settings Window (⌘,)**:
   - Native macOS Settings window scene with tabs:
     - General: Default view mode, Start location, Show hidden files toggle.
     - Tabs: Tab placement, close confirmation, session restore behavior.
     - Previews: Hover preview toggle, hover delay duration.
   - Changes take effect immediately via reactive `@AppStorage` / PreferencesService.
