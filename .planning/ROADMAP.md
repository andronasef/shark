# Roadmap: Shark

## Milestones

- ✅ **v1.0 Dolphin Core** — Phases 1–6 (recorded complete 2026-10-13); `milestones/v1.0-ROADMAP.md`.
- ✅ **v2.0 Finder Look, QTTabBar Power** — Phases 7–11 (recorded complete 2026-10-20); `milestones/v2.0-ROADMAP.md`.
- 🚧 **v2.1 Everyday Mac Workflows** — Phases 12–31, all three groups (started 2026-11-06).

## v2.1 — Everyday Mac Workflows

## Overview

Deliver the three authorized groups as native, safe daily workflows. Group 1 establishes collision handling and real virtual search locations before tags. Group 2 builds familiar Mac workflows on those foundations. Group 3 completes Quick Actions, grouping, Smart Folders, AirDrop, Print and Services. v2.1 is an internal GSD identity, not the public app version. No release, tag, deployment or submission is requested.

Every phase includes its meaningful tests, native UI inspection, Help/catalog/changelog updates and changed DESIGN rules; those obligations are not deferred to a final polish phase. Separate feature/fix commits remain required when a phase contains more than one capability. Phase-specific public-API research occurs before planning where needed. All requirements map exactly once; shared safety/verification rules apply throughout. Audit → complete → cleanup follows verified completion of all phases.

## Phases

### Group 1 — everyday essentials

- [ ] **Phase 12: Honest Sidebar and System Boundaries** — Remove fake tags and explain system Open/Save limits.
- [ ] **Phase 13: Safe Shared Collision Choices** — Replace, Keep Both, Skip, Stop and folder Merge across file-operation entry points.
- [ ] **Phase 14: Safe Archive Extraction** — Extract with staging, collision choices and native fallback.
- [ ] **Phase 15: Trash Recovery and Empty Trash** — Persistent Put Back and confirmed Finder-mediated emptying.
- [ ] **Phase 16: Extension Change Warnings** — Protect file-type changes across rename entry points.
- [ ] **Phase 17: iCloud Availability and Actions** — Accurate state badges, download and remove-download workflows.
- [ ] **Phase 18: Scoped Live Search Locations** — Spotlight, unindexed-volume fallback, history and real result actions.
- [ ] **Phase 19: Real Finder Tags** — Edit, display, sort and search actual Finder tags.

### Group 2 — expected Mac workflows

- [ ] **Phase 20: Recents and Configurable Places** — Real Recents, useful hideable defaults and honest AirDrop placement.
- [ ] **Phase 21: Transfer Progress and Controls** — Speed, remaining time, operation list, pause and safe cancel.
- [ ] **Phase 22: Aliases and Symbolic Links** — Native alias creation with an Option symlink alternate.
- [ ] **Phase 23: Spring-loaded Navigation** — Drag-hover and Space open folders, tabs and path segments.
- [ ] **Phase 24: Get Info and Batch Metadata** — Open with, Change All, Comments, Locked and selection summaries.
- [ ] **Phase 25: Connect to Server** — Validated native mounting handoff and credential-free recents.

### Group 3 — native actions and organization

- [ ] **Phase 26: Quick Actions** — Rotate, convert, create PDF and native Markup or explicit Preview handoff.
- [ ] **Phase 27: Group By Kind and Date** — Useful grouping with correct selection and keyboard behavior.
- [ ] **Phase 28: Smart Folders** — Save, reopen and manage persistent live searches.
- [ ] **Phase 29: Direct AirDrop Sharing** — Native receiver selection from the file context menu.
- [ ] **Phase 30: Print Selected Documents** — Discoverable printing and responder-correct Cmd-P.
- [ ] **Phase 31: Native macOS Services** — Real Services menu/pasteboard integration for selected files.

## Phase Details

### Phase 12: Honest Sidebar and System Boundaries
**Goal**: Users see only functional tag navigation and understand where macOS retains its own dialogs.
**Depends on**: Nothing (first phase of this milestone; v2.0 is recorded complete)
**Requirements**: HON-01, HON-02
**Success Criteria** (what must be TRUE):
  1. Sidebar color-name filters and inert All Tags are absent, including keyboard-focus stops, until actual tags are implemented in Phase 19.
  2. Help, welcome/onboarding and website FAQ plainly say that other applications' Open/Save dialogs remain the system interface.
  3. Existing sidebar favorites, locations, folder tree and keyboard navigation still work, and no public feature claim implies real tags have shipped.
**Plans**: TBD
**UI hint**: yes

### Phase 13: Safe Shared Collision Choices
**Goal**: Users can resolve conflicting file names consistently without silent loss of originals.
**Depends on**: Phase 12
**Requirements**: COLL-01, COLL-02, COLL-03, COLL-04
**Success Criteria** (what must be TRUE):
  1. Copy, move, paste and drag/drop conflicts show both items' preview, size and modified date with Replace, Keep Both, Skip, Stop and compatible Apply to all.
  2. Replace sends the existing destination to Trash and undo restores it; errors and Stop preserve originals and completed work remains undoable.
  3. Keep Both produces extension-preserving numeric suffixes while Duplicate still creates "copy" names.
  4. Folder Merge recursively handles child conflicts through the same choices without following directory symlinks into unsafe recursion.
**Plans**: TBD
**UI hint**: yes

### Phase 14: Safe Archive Extraction
**Goal**: Users can unpack supported archives beside their source with predictable, safe results.
**Depends on**: Phase 13
**Requirements**: EXTRACT-01, EXTRACT-02, EXTRACT-03
**Success Criteria** (what must be TRUE):
  1. Extract puts one top-level item directly beside its archive or several in an archive-named folder, asking the shared collision questions when necessary.
  2. Double-click keeps the default-app behavior; unsupported formats offer Archive Utility rather than a misleading success or format claim.
  3. Extraction stays responsive and reports progress/errors; malicious path/link fixtures cannot write outside allowed output, and failed/cancelled staging is cleaned safely.
**Plans**: TBD
**UI hint**: yes

### Phase 15: Trash Recovery and Empty Trash
**Goal**: Users can recover Shark-trashed items across launches and intentionally ask macOS to empty Trash.
**Depends on**: Phase 13, Phase 14
**Requirements**: TRASH-01, TRASH-02, TRASH-03
**Success Criteria** (what must be TRUE):
  1. After relaunch, Put Back restores tracked items to their original locations, asks collision choices and handles stale records without losing files.
  2. Untracked items offer Show in Finder; the interface does not pretend Shark can recover unknown original locations.
  3. Empty Trash confirms irreversibility, delegates to Finder and offers Show Trash in Finder on Automation denial; applicable distribution permissions/review notes explain the route honestly.
**Plans**: TBD
**UI hint**: yes

### Phase 16: Extension Change Warnings
**Goal**: Users cannot accidentally change a file's type during rename without choosing the extension change.
**Depends on**: Phase 15
**Requirements**: EXT-01
**Success Criteria** (what must be TRUE):
  1. Inline and other rename entry points ask Keep the existing extension / Use the new extension before changing or removing it.
  2. Normal stem renames, folders and dotfiles behave sensibly, and extensions remain visible in directory views.
**Plans**: TBD
**UI hint**: yes

### Phase 17: iCloud Availability and Actions
**Goal**: Users understand cloud file availability and can request or remove local downloads.
**Depends on**: Phase 16
**Requirements**: CLOUD-01, CLOUD-02
**Success Criteria** (what must be TRUE):
  1. Cloud-only, downloading, uploading, errors and shared-item badges reflect available public metadata; synchronized files have no unnecessary status icon.
  2. Eligible context-menu items provide Download Now / Remove Download and opening a cloud-only item requests download before opening.
  3. Available progress and errors are clear without invented values; unavailable account/provider validation is recorded as such.
**Plans**: TBD
**UI hint**: yes

### Phase 18: Scoped Live Search Locations
**Goal**: Users can find files beyond the current folder and act on live results as a navigation location.
**Depends on**: Phase 17
**Requirements**: SEARCH-01, SEARCH-02, SEARCH-03, SEARCH-04
**Success Criteria** (what must be TRUE):
  1. Cmd-F preserves immediate This Folder filtering and exposes scope/Name only choices; Option-Cmd-F selects This Mac.
  2. Deep Spotlight search streams live uncapped name/content results with Searching state, best-match default and usable ordinary sort controls, without stale-query flashes.
  3. Results show original locations; Back/Escape return to the originating folder, and file actions/Quick Look target real URLs while paste/create destinations remain explicit.
  4. Subfolders on unindexed volumes offers cancellable name-only walking with honest progress and contents limitations.
**Plans**: TBD
**UI hint**: yes

### Phase 19: Real Finder Tags
**Goal**: Users can organize files with the same tags Finder reads and writes.
**Depends on**: Phase 18
**Requirements**: TAG-01, TAG-02, TAG-03
**Success Criteria** (what must be TRUE):
  1. Context-menu color dots/custom Tags and inspector edits change real Finder metadata for one or several selected files.
  2. Standard/used sidebar tags perform actual Spotlight tag searches rather than filtering names.
  3. Tag dots appear in all four views in the agreed positions, with three-dot/+N overflow and accessible labels; optional sortable Tags column starts off.
**Plans**: TBD
**UI hint**: yes

### Phase 20: Recents and Configurable Places
**Goal**: Users can start from recently used files and familiar configurable Mac places.
**Depends on**: Phase 18, Phase 19
**Requirements**: PLACE-01, PLACE-02, PLACE-03
**Success Criteria** (what must be TRUE):
  1. Recents shows Spotlight files used in the past 30 days, newest first, with working result actions rather than opening Home.
  2. Applications, Desktop, Documents, Downloads, available iCloud Drive, Network and Recents have useful default entries and independent hide/show settings.
  3. Favorites, mounted-volume eject and folder tree still work; AirDrop is a sharing action and no longer a fake browsable directory.
**Plans**: TBD
**UI hint**: yes

### Phase 21: Transfer Progress and Controls
**Goal**: Users can assess and control long copies without risking original files.
**Depends on**: Phase 13, Phase 20
**Requirements**: TRANSFER-01, TRANSFER-02
**Success Criteria** (what must be TRUE):
  1. A copy lasting about two seconds shows speed/time remaining in the status bar and opens an operation list when clicked.
  2. Pause/Resume and Cancel work while browsing stays responsive.
  3. Cancel removes incomplete output while preserving sources, old destinations and completed work, including when collision choices or merges occurred.
**Plans**: TBD
**UI hint**: yes

### Phase 22: Aliases and Symbolic Links
**Goal**: Users can create native file references without duplicating target contents.
**Depends on**: Phase 13, Phase 21
**Requirements**: LINK-01, LINK-02
**Success Criteria** (what must be TRUE):
  1. Make Alias creates a real macOS alias beside its original using safe "name alias" naming.
  2. Holding Option reveals Make Symbolic Link; the resulting symlink points to the original without modifying it, including when reference names collide.
**Plans**: TBD
**UI hint**: yes

### Phase 23: Spring-loaded Navigation
**Goal**: Users can reach nested drop destinations by holding a drag over navigation targets.
**Depends on**: Phase 22
**Requirements**: SPRING-01, SPRING-02
**Success Criteria** (what must be TRUE):
  1. Drag-hover over folders, tabs or path segments opens after the system delay; Space opens the active target immediately.
  2. Leaving or ending a drag cancels pending opening, system preferences are respected and drops continue to resolve into the intended destination.
**Plans**: TBD
**UI hint**: yes

### Phase 24: Get Info and Batch Metadata
**Goal**: Users can inspect and edit everyday file metadata and app associations for one or many items.
**Depends on**: Phase 19, Phase 23
**Requirements**: INFO-01, INFO-02
**Success Criteria** (what must be TRUE):
  1. Single-item Get Info edits Comments/Locked, chooses Open with and confirms an accurate system Change All action.
  2. Multi-item Get Info shows count, total size and kinds and applies tags/Open with to the selection with accurate per-item failures.
  3. Existing inspector metadata, checksums and file actions remain available without misleading app-association claims.
**Plans**: TBD
**UI hint**: yes

### Phase 25: Connect to Server
**Goal**: Users can ask macOS to mount supported servers and return to them safely.
**Depends on**: Phase 20, Phase 24
**Requirements**: SERVER-01, SERVER-02
**Success Criteria** (what must be TRUE):
  1. Go > Connect to Server opens a native address/recent-server window, validates supported smb/afp/nfs URLs and hands the connection to macOS.
  2. Mounted servers appear in the existing volume sidebar; invalid/unsupported addresses get clear errors.
  3. Recent addresses survive relaunch without persisted passwords or other embedded credentials.
**Plans**: TBD
**UI hint**: yes

### Phase 26: Quick Actions
**Goal**: Users can perform useful image/PDF actions directly from applicable file selections.
**Depends on**: Phase 13, Phase 25
**Requirements**: QUICK-01, QUICK-02, QUICK-03
**Success Criteria** (what must be TRUE):
  1. Rotate and Convert Image operate on applicable image selections using native facilities and preserve originals for derived output with safe collision naming.
  2. Create PDF produces a usable document from supported selections in predictable order without silently replacing existing output.
  3. Markup works through a public native surface or an explicitly labeled Preview handoff; unsupported selections do not get inert or misleading commands.
**Plans**: TBD
**UI hint**: yes

### Phase 27: Group By Kind and Date
**Goal**: Users can organize list/icon contents into understandable groups without losing navigation control.
**Depends on**: Phase 26
**Requirements**: GROUP-01, GROUP-02
**Success Criteria** (what must be TRUE):
  1. Kind/Date grouping displays useful stable headers in list and icon views; None restores normal ordering and within-group sorting works.
  2. Keyboard range selection and file actions follow visible order across group boundaries and mode changes.
  3. Grouping large directories remains responsive without invalidating selected file identities.
**Plans**: TBD
**UI hint**: yes

### Phase 28: Smart Folders
**Goal**: Users can return to named live searches without recreating the query.
**Depends on**: Phase 18, Phase 27
**Requirements**: SMART-01, SMART-02
**Success Criteria** (what must be TRUE):
  1. Saving a deep search preserves its name, query, scope and Name only state and provides a persistent sidebar entry that reopens live results after relaunch.
  2. Renaming/removing a Smart Folder affects only its definition; matching files remain untouched.
  3. Missing search roots and empty results have clear states; Help accurately describes Shark persistence without unimplemented Finder interoperability claims.
**Plans**: TBD
**UI hint**: yes

### Phase 29: Direct AirDrop Sharing
**Goal**: Users can send applicable files with native AirDrop directly from their context menu.
**Depends on**: Phase 20, Phase 28
**Requirements**: AIR-01
**Success Criteria** (what must be TRUE):
  1. AirDrop is available directly for eligible selected files and opens normal macOS receiver selection through NSSharingService.
  2. Unavailable service/selection states are honest and do not launch Finder as a fake browsable AirDrop folder.
**Plans**: TBD
**UI hint**: yes

### Phase 30: Print Selected Documents
**Goal**: Users can start supported file printing with familiar native controls and Cmd-P.
**Depends on**: Phase 29
**Requirements**: PRINT-01, PRINT-02
**Success Criteria** (what must be TRUE):
  1. Cmd-P and a discoverable menu item print supported selections through native facilities or an accurately labeled system-app handoff.
  2. Unsupported files receive clear behavior, while text editors/terminal or other active responders do not accidentally trigger file printing.
**Plans**: TBD
**UI hint**: yes

### Phase 31: Native macOS Services
**Goal**: Users can apply installed macOS Services to their selected files through the real system integration.
**Depends on**: Phase 30
**Requirements**: SERVICE-01, SERVICE-02
**Success Criteria** (what must be TRUE):
  1. The real system Services menu receives selected file URLs through the responder chain/pasteboard and can invoke applicable installed Services.
  2. Availability tracks selection/focus without breaking copy, ordinary text selection or keyboard behavior; unavailable local Services verification is reported honestly.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 12. Honest Sidebar and System Boundaries | v2.1 | 0/TBD | Not started | - |
| 13. Safe Shared Collision Choices | v2.1 | 0/TBD | Not started | - |
| 14. Safe Archive Extraction | v2.1 | 0/TBD | Not started | - |
| 15. Trash Recovery and Empty Trash | v2.1 | 0/TBD | Not started | - |
| 16. Extension Change Warnings | v2.1 | 0/TBD | Not started | - |
| 17. iCloud Availability and Actions | v2.1 | 0/TBD | Not started | - |
| 18. Scoped Live Search Locations | v2.1 | 0/TBD | Not started | - |
| 19. Real Finder Tags | v2.1 | 0/TBD | Not started | - |
| 20. Recents and Configurable Places | v2.1 | 0/TBD | Not started | - |
| 21. Transfer Progress and Controls | v2.1 | 0/TBD | Not started | - |
| 22. Aliases and Symbolic Links | v2.1 | 0/TBD | Not started | - |
| 23. Spring-loaded Navigation | v2.1 | 0/TBD | Not started | - |
| 24. Get Info and Batch Metadata | v2.1 | 0/TBD | Not started | - |
| 25. Connect to Server | v2.1 | 0/TBD | Not started | - |
| 26. Quick Actions | v2.1 | 0/TBD | Not started | - |
| 27. Group By Kind and Date | v2.1 | 0/TBD | Not started | - |
| 28. Smart Folders | v2.1 | 0/TBD | Not started | - |
| 29. Direct AirDrop Sharing | v2.1 | 0/TBD | Not started | - |
| 30. Print Selected Documents | v2.1 | 0/TBD | Not started | - |
| 31. Native macOS Services | v2.1 | 0/TBD | Not started | - |

## Completion Gate

After every phase passes, run the autonomous milestone lifecycle: audit all 47 requirements and cross-feature integrations; resolve or explicitly report gaps; complete/archive only genuinely verified work; cleanup only under the workflow's applicable approval rules. No public release actions. Full Swift build/test, website build, native UI checks and desktop/mobile features-page checks are required evidence, with system/account/human limits recorded rather than fabricated.
