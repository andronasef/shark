# Roadmap: Shark

## Milestones

- ✅ **v1.0 Dolphin Core** - Phases 1-6 (shipped 2026-10-13) — see milestones/v1.0-ROADMAP.md
- 🚧 **v2.0 Finder Look, QTTabBar Power** - Phases 7-11 (in progress)

## Overview

v2.0 keeps Shark looking like native macOS Finder and adds the power of QTTabBar and the ease of Windows File Explorer: pro tabs with session restore, Explorer clipboard and undo, cascading subfolder menus and hover previews, a command palette for everything, and a final Finder-fidelity polish pass. Every phase is verified by driving the real app with computer-use (cua-driver).

## Phases

- [ ] **Phase 7: Pro Tab Strip & Session Restore** - QTTabBar-grade tabs: reorder, pin, lock, colour, reopen closed, persistence
- [ ] **Phase 8: Explorer Ergonomics** - Cut/Copy/Paste, undo, inline rename, copy path, rich status bar, path bar, folder sizes, address bar
- [ ] **Phase 9: QTTabBar Folder Power** - Cascading subfolder menus, hover previews, recent/frequent folders, tab groups
- [ ] **Phase 10: Command Palette, Menus & Keyboard** - ⌘K palette, complete menu bar, type-to-select, settings window
- [ ] **Phase 11: Finder Fidelity Polish** - Visual pass, real Columns view, states, accessibility, DESIGN.md

## Phase Details

### Phase 7: Pro Tab Strip & Session Restore
**Goal**: Replace the Finder sub-toolbar tab capsule with a full QTTabBar-grade tab strip that looks like Finder/Safari tabs and persists across launches.
**Depends on**: Phase 6
**Requirements**: TAB-01, TAB-02, TAB-03, TAB-04, TAB-05, TAB-06, TAB-07
**Success Criteria** (what must be TRUE):
  1. User can drag a tab to a new position, middle-click to close it, and ⇧⌘T reopens the last closed tab at its path.
  2. Tab context menu offers Duplicate, Pin, Lock, Close Others, Close to the Right, Colour, Copy Path, and each works.
  3. Quitting and relaunching Shark restores the same tabs, pins, colours, paths, split state and view modes.
  4. ⌘-double-click on a folder opens it in a new background tab; ⌥⌘1–9 jump to tabs.
**Plans**: TBD
**UI hint**: yes

### Phase 8: Explorer Ergonomics
**Goal**: Give Shark the everyday ease of Windows File Explorer: clipboard file operations, undo, inline rename, copy path, informative status and path bars, folder sizes, and a forgiving address bar.
**Depends on**: Phase 7
**Requirements**: EXP-01, EXP-02, EXP-03, EXP-04, EXP-05, EXP-06, EXP-07, EXP-08, EXP-09
**Success Criteria** (what must be TRUE):
  1. User can ⌘X a file in one tab and ⌘V it in another; the file moves and ⌘Z moves it back.
  2. Pressing Return on a selected file starts inline rename with the base name selected.
  3. Status bar shows "N items, M selected (size), X GB available" and live progress for running copies with a cancel button.
  4. Context menu offers Copy Path, Open in Terminal, Open With, Compress, Calculate Size.
  5. ⌘L edits the address; Tab autocompletes; an invalid path shows an inline error and does not navigate.
**Plans**: TBD
**UI hint**: yes

### Phase 9: QTTabBar Folder Power
**Goal**: Bring QTTabBar's signature folder navigation: cascading subfolder menus from breadcrumbs and folders, hover previews, recent/frequent folders, and saved tab groups.
**Depends on**: Phase 7
**Requirements**: QT-01, QT-02, QT-03, QT-04, QT-05
**Success Criteria** (what must be TRUE):
  1. Clicking the chevron after any breadcrumb segment shows its subfolders as a menu that cascades into deeper subfolders on hover; choosing one navigates.
  2. Hovering an image file for ~0.6s shows a thumbnail preview; hovering a text file shows its first lines.
  3. Sidebar shows Recent and Frequent folders that update as the user navigates.
  4. User can save open tabs as a group and reopen the group later.
**Plans**: TBD
**UI hint**: yes

### Phase 10: Command Palette, Menus & Keyboard
**Goal**: Make every capability findable by eye and doable by key: a ⌘K command palette, a complete menu bar, type-to-select, and a Settings window.
**Depends on**: Phase 8, Phase 9
**Requirements**: CMD-01, CMD-02, CMD-03, CMD-04
**Success Criteria** (what must be TRUE):
  1. ⌘K opens a palette; typing "split" runs Toggle Split, typing "dow" jumps to Downloads, typing "/usr/loc" navigates there.
  2. Every toolbar and context action appears in the menu bar with its shortcut; F3, F4, F11 and Space work.
  3. Typing letters in a folder selects the first matching item in every view.
  4. ⌘, opens Settings, and changes there apply immediately and persist.
**Plans**: TBD
**UI hint**: yes

### Phase 11: Finder Fidelity Polish
**Goal**: Make Shark indistinguishable from Finder in look and feel while keeping its power: visual pass in light and dark, a real Columns view, honest empty/error states, accessibility, and DESIGN.md.
**Depends on**: Phase 10
**Requirements**: POL-01, POL-02, POL-03, POL-04, POL-05
**Success Criteria** (what must be TRUE):
  1. Side-by-side screenshots against Finder in light and dark show matching toolbar, sidebar, list and icon styling.
  2. Columns view browses with Miller columns and keyboard arrows.
  3. Opening a protected folder shows a permission state with a "Grant Full Disk Access" action.
  4. VoiceOver reads every toolbar control and row; DESIGN.md exists and matches the build.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 7. Pro Tab Strip & Session Restore | v2.0 | 0/TBD | Not started | - |
| 8. Explorer Ergonomics | v2.0 | 0/TBD | Not started | - |
| 9. QTTabBar Folder Power | v2.0 | 0/TBD | Not started | - |
| 10. Command Palette, Menus & Keyboard | v2.0 | 0/TBD | Not started | - |
| 11. Finder Fidelity Polish | v2.0 | 0/TBD | Not started | - |
