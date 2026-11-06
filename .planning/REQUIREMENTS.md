# Requirements: Shark

**Milestone:** v2.1 Everyday Mac Workflows (internal planning identifier)
**Defined:** 2026-11-06
**Core Value:** Native Finder familiarity with safe, fast daily file work reachable by mouse and keyboard.

## v2.1 Requirements

Every requirement below is authorized current scope, including Group 3. Details and safety invariants in `EVERYDAY-MAC-MILESTONE.md` apply to every phase. Check a requirement only after implementation, meaningful verification and its feature commit. Archived v1.0/v2.0 requirements retain their historical statuses in `milestones/`.

### Honest baseline (HON)

- [ ] **HON-01**: Users no longer see fake color-name filters or an inert All Tags action presented as Finder tags, and keyboard focus skips removed rows until real tags land.
- [ ] **HON-02**: Help, onboarding and the website FAQ accurately explain that other apps' Open/Save dialogs remain the system interface.

### Collision choices (COLL)

- [ ] **COLL-01**: Copy, move, paste and drag/drop present one consistent Replace / Keep Both / Skip / Stop dialog when destination names collide, comparing both items' thumbnail, size and modified date.
- [ ] **COLL-02**: Users can apply compatible choices to remaining conflicts in one operation and can recursively Merge colliding folders while still deciding child conflicts.
- [ ] **COLL-03**: Replace preserves the old destination in Trash with undo; failures and Stop preserve originals and keep completed changes undoable.
- [ ] **COLL-04**: Keep Both creates extension-preserving "name 2", "name 3" names, while Duplicate retains "name copy" behavior; recursive operations do not follow directory symlinks into unsafe copies.

### Archive extraction (EXTRACT)

- [ ] **EXTRACT-01**: Users can Extract supported archives beside the source from a context-menu action; one top-level item appears directly and multiple items appear under the archive's name, with shared collision choices.
- [ ] **EXTRACT-02**: Unsupported formats offer Archive Utility; double-click continues to use the configured default app, and responsive progress/errors make extraction state clear.
- [ ] **EXTRACT-03**: Malicious absolute/traversal/link paths cannot write outside safe staging/output; failure or cancellation cleans incomplete staging without losing existing files.

### Trash recovery (TRASH)

- [ ] **TRASH-01**: Users can Put Back items Shark trashed after relaunch using persisted original/Trash URLs, with shared collision handling and safe stale-record pruning.
- [ ] **TRASH-02**: Items without Shark recovery records offer Show in Finder rather than a falsely available Put Back.
- [ ] **TRASH-03**: Empty Trash clearly confirms irreversibility and asks Finder to perform it; Automation denial offers Show Trash in Finder, with applicable distribution configuration and App Review notes.

### Extension changes (EXT)

- [ ] **EXT-01**: Rename entry points warn before changing/removing a file extension and offer Keep the old extension / Use the new extension; folder/dotfile cases are handled sensibly and extensions remain visible.

### iCloud (CLOUD)

- [ ] **CLOUD-01**: Users see accurate cloud-only, downloading, uploading, error and shared-item badges where public APIs supply those states, without clutter for fully synchronized files.
- [ ] **CLOUD-02**: Download Now / Remove Download apply to eligible items; opening a cloud-only item requests download first and reports available progress/errors without fabricated values.

### Scoped live search (SEARCH)

- [ ] **SEARCH-01**: Cmd-F retains immediate This Folder filtering and reveals This Folder / Subfolders / This Mac scopes with a Name only toggle; Option-Cmd-F chooses This Mac.
- [ ] **SEARCH-02**: Spotlight deep search matches names and optionally contents, delivers live uncapped results with Searching status, rejects stale results and defaults to best match with ordinary sorting available.
- [ ] **SEARCH-03**: Results behave as a navigable tab location showing source paths; Back and Escape return to the originating folder, while file actions and Quick Look target actual result URLs.
- [ ] **SEARCH-04**: Subfolders on unindexed volumes has a cancellable name-only filesystem walk with honest progress/contents limitations and unambiguous creation/paste destinations in virtual locations.

### Finder tags (TAG)

- [ ] **TAG-01**: Users can read/write real Finder tags, choose standard color dots or custom Tags… in context menus, and edit inspector tags for one or multiple selected items.
- [ ] **TAG-02**: The sidebar lists standard/used tags and opens a real Spotlight tag search when one is chosen.
- [ ] **TAG-03**: List/column names show trailing tag dots; icon/gallery names show dots below, capped at three plus +N, with accessible labels and an optional sortable Tags column off by default.

### Recents and places (PLACE)

- [ ] **PLACE-01**: Recents lists files last used within 30 days through Spotlight, newest first, as a virtual location with ordinary actions instead of navigating Home.
- [ ] **PLACE-02**: Recents, Applications, Desktop, Documents, Downloads, available iCloud Drive and Network are usable default places and can each be hidden in Settings; favorites, folder tree and mounted-volume eject continue to work.
- [ ] **PLACE-03**: AirDrop is a sharing action rather than a fake browsable location, with no obsolete sidebar claims in Help or the public catalog.

### Transfer controls (TRANSFER)

- [ ] **TRANSFER-01**: Copies lasting about two seconds show meaningful speed/time remaining in the status bar; clicking reveals an operation list with Pause / Resume and Cancel.
- [ ] **TRANSFER-02**: Cancel cleans partial output while preserving sources, pre-existing destinations and completed work; paused transfers resume safely without blocking browsing.

### Aliases and symbolic links (LINK)

- [ ] **LINK-01**: Make Alias creates a real macOS alias next to its original as "name alias" with safe collision naming.
- [ ] **LINK-02**: Holding Option exposes Make Symbolic Link as the alternate context-menu action, creating an actual symlink without changing the target.

### Spring loading (SPRING)

- [ ] **SPRING-01**: Drag-hover over a folder, tab or path segment opens it after the system spring-loading delay and Space opens it immediately.
- [ ] **SPRING-02**: Leaving/ending a drag cancels pending navigation, system spring-loading preferences are respected, and existing drop/mouse navigation remains intact.

### Get Info (INFO)

- [ ] **INFO-01**: A single-item Get Info offers Open with, confirmed Change All…, editable Comments and Locked using public system semantics.
- [ ] **INFO-02**: Multiple selected items have a count, total size and kinds summary and can receive batch tags or Open with changes with accurate per-item errors.

### Server connections (SERVER)

- [ ] **SERVER-01**: Go > Connect to Server… opens a native address/recent-server window and delegates validated smb/afp/nfs addresses to macOS; mounted volumes appear through existing notifications.
- [ ] **SERVER-02**: Recent servers persist without credentials, unsupported/invalid addresses get an explanation, and Shark implements no network protocol stack.

### Quick Actions (QUICK)

- [ ] **QUICK-01**: Applicable image selections offer working Rotate and Convert Image actions through public native facilities, preserving originals for derived output with safe collision handling.
- [ ] **QUICK-02**: Users can create a PDF from applicable selected files through native facilities with predictable ordering and safe output naming.
- [ ] **QUICK-03**: Markup is a working native action or explicitly labeled Preview handoff, with appropriate availability and accurate Help/catalog claims.

### Grouping (GROUP)

- [ ] **GROUP-01**: List and icon views offer Group By Kind / Date / None with useful stable headers and ordinary sorting inside groups.
- [ ] **GROUP-02**: Selection, keyboard/range navigation, file actions and large-directory responsiveness remain correct across grouped views and mode changes.

### Smart Folders (SMART)

- [ ] **SMART-01**: Users can save the current deep search's name, query, scope and Name only setting and reopen it as a live search from persistent sidebar entries.
- [ ] **SMART-02**: Users can rename/remove saved definitions without deleting matching files; missing scopes and empty results are explained, and no unimplemented Finder .savedSearch compatibility is claimed.

### AirDrop (AIR)

- [ ] **AIR-01**: Applicable selections offer a direct working AirDrop context-menu action through NSSharingService with normal macOS receiver selection and honest availability.

### Print (PRINT)

- [ ] **PRINT-01**: Cmd-P and a discoverable menu action print supported selected documents through native facilities or a clearly labeled system-app handoff, with sensible unsupported-file behavior.
- [ ] **PRINT-02**: Print honors the active responder/editor and selection so unrelated text controls or terminal workflows do not trigger file printing unexpectedly.

### Services (SERVICE)

- [ ] **SERVICE-01**: Native macOS Services can receive the selected file URLs through the responder chain/pasteboard, with a real system-populated menu rather than fake entries.
- [ ] **SERVICE-02**: Service availability tracks the actual selection and focus, and existing copy, selection and keyboard workflows remain intact.

## Cross-cutting acceptance

These are completion rules for every owning phase, not duplicate feature requirements: native macOS 14+ accessibility; responsive UI; non-trivial logic tests; relevant Help/MouseHelp.zones and mouse settings; implemented-only feature catalog/home highlights; CHANGELOG and changed DESIGN rules in the same feature commit. Run Swift build/test and website build, inspect native UI and desktop/mobile features layout, and record unavailable human/account/system validation honestly. The autonomous lifecycle ends with a requirement/integration audit; no feature-only “polish phase” substitutes for these obligations.

## Future Requirements

No capability from the three authorized groups is deferred. Git badges and an integrated file diff remain outside this milestone. Any extra requirements discovered during execution must be explicitly recorded and mapped rather than silently expanding or shrinking the approved groups.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Protocol stacks or proprietary cloud clients | macOS mounts servers; native file/iCloud APIs are sufficient |
| Private Finder internals or system Open/Save replacement | Unsupported behavior and outside the user-approved direction |
| Finder .savedSearch interchange by default | Smart Folder persistence does not imply unimplemented compatibility |
| Deployment, release version/tag changes, App Store submission | User requested implementation and verification only |
| Permanent deletion of real user files during QA | Use temporary fixtures and mocked irreversible actions |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| HON-01 | Phase 12 | Pending |
| HON-02 | Phase 12 | Pending |
| COLL-01 | Phase 13 | Pending |
| COLL-02 | Phase 13 | Pending |
| COLL-03 | Phase 13 | Pending |
| COLL-04 | Phase 13 | Pending |
| EXTRACT-01 | Phase 14 | Pending |
| EXTRACT-02 | Phase 14 | Pending |
| EXTRACT-03 | Phase 14 | Pending |
| TRASH-01 | Phase 15 | Pending |
| TRASH-02 | Phase 15 | Pending |
| TRASH-03 | Phase 15 | Pending |
| EXT-01 | Phase 16 | Pending |
| CLOUD-01 | Phase 17 | Pending |
| CLOUD-02 | Phase 17 | Pending |
| SEARCH-01 | Phase 18 | Pending |
| SEARCH-02 | Phase 18 | Pending |
| SEARCH-03 | Phase 18 | Pending |
| SEARCH-04 | Phase 18 | Pending |
| TAG-01 | Phase 19 | Pending |
| TAG-02 | Phase 19 | Pending |
| TAG-03 | Phase 19 | Pending |
| PLACE-01 | Phase 20 | Pending |
| PLACE-02 | Phase 20 | Pending |
| PLACE-03 | Phase 20 | Pending |
| TRANSFER-01 | Phase 21 | Pending |
| TRANSFER-02 | Phase 21 | Pending |
| LINK-01 | Phase 22 | Pending |
| LINK-02 | Phase 22 | Pending |
| SPRING-01 | Phase 23 | Pending |
| SPRING-02 | Phase 23 | Pending |
| INFO-01 | Phase 24 | Pending |
| INFO-02 | Phase 24 | Pending |
| SERVER-01 | Phase 25 | Pending |
| SERVER-02 | Phase 25 | Pending |
| QUICK-01 | Phase 26 | Pending |
| QUICK-02 | Phase 26 | Pending |
| QUICK-03 | Phase 26 | Pending |
| GROUP-01 | Phase 27 | Pending |
| GROUP-02 | Phase 27 | Pending |
| SMART-01 | Phase 28 | Pending |
| SMART-02 | Phase 28 | Pending |
| AIR-01 | Phase 29 | Pending |
| PRINT-01 | Phase 30 | Pending |
| PRINT-02 | Phase 30 | Pending |
| SERVICE-01 | Phase 31 | Pending |
| SERVICE-02 | Phase 31 | Pending |

**Coverage:** 47 requirements; 47 mapped exactly once; 0 unmapped. All Pending at initialization.

---
*Last updated: 2026-11-06 after authorized all-group milestone definition.*
