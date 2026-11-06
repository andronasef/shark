# Everyday Mac Features — authorized scope

Date: 2026-11-06

## Authority and execution

The user explicitly requested: “using $gsd-autonomous make all the 3 groups”.
This supersedes the earlier suggestion to defer Group 3. Implement all groups,
including their integration, tests, Help, design rules, feature catalog, and
changelog. Do not stop after writing plans or after Group 1. Use the installed
gsd-autonomous skill and its workflow. Bootstrap a new milestone because the
existing v2.0 milestone is recorded complete. Planning milestone identifiers
are not the public app version (currently 1.0.0-alpha.4); avoid an accidental
public version bump or release. No publishing, PR, or deployment is requested.

The previous discussion is in thread cdf53feb-a41c-4e04-b1aa-437deff2a08f.
The full user-approved decisions relevant to implementation are captured below.
The latest request authorizes choosing reasonable native defaults for Group 3
and routine implementation choices without repeating the earlier questions.
Preserve actual safety and human validation gates from the invoked workflow.

## Product rules

- Power users remain the primary audience; everyday Mac users moving off Finder
  are a second audience. Matching Finder's everyday capabilities is the minimum.
- Keep the existing native macOS Finder visual direction and macOS 14 minimum.
- Remote mounting goes through macOS; Shark implements no network protocol stack.
- Open/Save dialogs in other applications remain the system interface. Say so
  accurately in Help, onboarding, and the website FAQ where appropriate.
- Public feature inventory lists implemented behavior only, never roadmap work.
- Follow AGENTS.md, PRODUCT.md and DESIGN.md. Add meaningful unit tests for
  non-trivial logic. Run swift build, swift test, and the website build.
- One conventional commit per feature or fix, with its docs and catalog updates.
- Check visible UI in the running native app. Never script system privacy prompts;
  leave those to the user. Do not infer UI success from compilation.
- Never add dependencies when system APIs or a little Swift/AppKit suffice.
- Do not manipulate the user's real files or empty their real Trash during QA;
  use isolated temporary fixtures for copy, replace, merge, archive, and restore.

## Existing work

At intake HEAD was f9bd33d and the only untracked item was .claude/.
The old volume-eject changes were already committed as a19a03d. Do not commit,
remove or overwrite unrelated .claude/ content. The existing GSD files describe
completed phases 7–11, and older milestones/quick-task history must be preserved.

## Group 1 — everyday essentials

Implementation order: hide fake tags, collision handling, extraction, Trash,
extension warning, iCloud, search, real tags. Dependencies can be adjusted for
correctness, but real sidebar tags require real search.

### Honest sidebar patch

Hide the current fake Tags section and its empty All Tags action until real
Finder tags land. Remove its keyboard-focus entries too. Today's color entries
merely set filterText to a color name and must not pretend to query actual tags.
This is a separate fix commit. No external release is requested.

### Shared collision handling

- Copy, move, paste, drag/drop, extraction and Put Back share a collision UI:
  Replace / Keep Both / Skip / Stop; folder/folder collisions also offer Merge.
- Show both items' thumbnail, size and modification date, and Apply to all for
  the operation. Be explicit about safe application across mixed collision types.
- Replace sends the original destination to Trash and supports undo restoring it.
  Handle partial failures without losing either original. Stop preserves completed
  work and offers undo for it. Never silently overwrite or permanently delete.
- Keep Both uses "name 2", "name 3", preserving extension; Duplicate continues
  to use "name copy". Merge recursively handles child collisions through the same
  mechanism; never follow directory symlinks into unsafe recursive copies.

### Extract

- Context-menu Extract; double-click still opens the configured default app.
- Use macOS's built-in archive facilities/tools, no third-party library. Verify
  actual supported formats rather than assume every rar/7z archive is readable.
  Fall back to Archive Utility for unsupported archives with honest UI.
- Extract next to the archive: one top-level item comes out directly; multiple
  items go in a folder named after the archive. Collisions use the shared UI.
- Untrusted archives must not escape the staging/extraction root through absolute
  paths, traversal, symlinks or hard links; validate and test before extraction.
- Keep the UI responsive, show errors, and clean up incomplete staging safely.

### Trash

- Persist original locations and returned Trash URLs for items Shark trashes.
- Put Back restores only tracked items; collisions use the common dialog. Prune
  stale records safely and preserve records across relaunches.
- For items Shark cannot restore, offer Show in Finder.
- Empty Trash delegates to Finder, behind a clear irreversible-action confirmation.
  Handle Automation denial by offering Show Trash in Finder.
- Configure distribution permissions and App Review notes for the App Store route
  as applicable; do not promise Apple's approval or request it during this task.
- Earlier terminal access to ~/.Trash failed with Operation not permitted. This
  is evidence about that process, not proof of the app's permission state. Avoid
  claiming a universal Full Disk Access requirement without checking APIs.

### Extension warnings

Always show extensions. Renaming to another extension prompts Keep ".pdf" /
Use ".txt" (using actual extensions). Cover inline and other rename entry points
and extension removal, while handling dotfiles and folders sensibly.

### iCloud

- File badges for cloud-only, downloading with available progress, uploading,
  errors, and shared items (person badge). No synced-state clutter.
- Download Now and Remove Download from the context menu where supported.
- Opening a cloud-only item requests download first and shows meaningful status.
- Use public native APIs; do not fabricate progress or sharing state unavailable
  on a given OS/provider. Test pure status mapping; report hardware/account limits.

### Search

- Existing Cmd-F field retains immediate current-folder filtering.
- Scope bar: This Folder / Subfolders / This Mac. Deep scopes search names and
  contents via Spotlight; Name only toggle. Option-Cmd-F chooses This Mac.
- Deep results are a tab navigation location, with source path/location visible;
  Back returns to the originating folder. Escape clears and returns to the folder.
- Live, uncapped results and a Searching indicator. Best match first, with normal
  sorting still available. Reject obsolete asynchronous results.
- On unindexed disks/network volumes, Subfolders provides a cancellable name-only
  filesystem walk with progress and an honest explanation of contents limitations.
- Actions, Quick Look and selection operate on actual result URLs. New-item and
  paste destinations must remain unambiguous in a virtual location.

### Finder tags

- Read/write real Finder tag metadata; standard color dots plus custom Tags… in
  context menus; editable inspector field; multi-selection support.
- Sidebar shows real standard/used tags; click queries tags through Spotlight.
- Dots after name in list and column views; below name in icon/gallery views.
  At most three visible dots plus +N overflow. Optional sortable Tags list column,
  off by default. Reuse native conventions and ensure accessible labels.

## Group 2 — expected Mac workflows

1. Recents: Spotlight last-used date in the past 30 days, newest first, files as
   a virtual results location with normal file actions. No fake Home shortcut.
2. Sidebar defaults: Recents, Applications, Desktop, Documents, Downloads, iCloud
   Drive when available, and Network; each hideable in Settings. AirDrop is a
   sharing action, not a browsable fake filesystem location. Preserve favorites,
   mounted volumes/eject, and folder tree functionality.
3. Long copies (about >2 seconds): speed/time remaining in status bar; click opens
   operation list with Pause and Cancel. Clean up partial output on cancellation;
   preserve source and previously existing destination, and retain completed work.
4. Make Alias: real macOS alias next to original as "name alias". Option reveals
   Make Symbolic Link instead. Handle collisions through safe naming.
5. Spring-loaded folders: drag-hover folders, tabs, and path segments opens after
   the system spring-loading delay; Space opens immediately. Cancel timers when
   drag leaves/ends, avoid unwanted navigation, and respect system preferences.
6. Get Info: single item Open with and Change All…, editable Comments and Locked.
   Multi-item summary count/total size/kinds plus batch tags and Open with. Use
   accurate Launch Services semantics and explicit confirmation for Change All.
7. Go > Connect to Server…: native small address/recent-server window, delegates
   supported smb/afp/nfs addresses to macOS; mounted volume appears through existing
   notifications. Validate scheme/address; never persist server credentials.

## Group 3 — in scope now

These capabilities were identified, but detailed design was deferred before the
latest user instruction. Choose restrained native defaults consistent with the
existing app; record choices in phase context/design docs and implement them.

1. Quick Actions: Rotate images, Markup, Create PDF, Convert Image. Use public
   macOS APIs and tools, operate on applicable selections, preserve originals
   when producing derivatives, and make handoffs explicit (e.g. Markup in Preview
   if native in-app Markup cannot be provided through a supported API). No inert
   entries, fictitious system integrations, or disabled placeholder feature claims.
2. Group By: Kind and Date for list and icon views, stable ordering within groups,
   useful group headers, None to return to normal sorting. Preserve selection,
   keyboard range navigation, performance, and existing file actions.
3. Smart Folders: save/reopen live searches, including query, scope and Name only,
   persistent names and sidebar access, rename/remove saved definitions without
   deleting matching files. Reuse search instead of creating another index. Do
   not claim Finder .savedSearch interoperability unless actually implemented.
4. Direct AirDrop context-menu action using NSSharingService; enabled only when
   appropriate and available; respect normal macOS receiver selection.
5. Print (Cmd-P) for supported documents through public native printing or an
   accurately labeled system-app handoff. Avoid intercepting unrelated editor
   responders; unsupported files get honest behavior.
6. Services: integrate native macOS Services for selected file URLs using the
   responder chain/pasteboard. Verify actual Services behavior; do not populate
   fake commands in a menu bearing that name.

## Acceptance and reporting

Track all requirements to phases and verification evidence. Run the full Swift
suite, website build, and focused UI checks of the changed workflows. Include
desktop and mobile features-page layout checks after catalog changes using the
available permitted browser tooling; do not claim checks that were not performed.
GSD phase plans, summaries, verification and STATE must truthfully distinguish
implemented, tested, user-validation-needed and blocked. Complete the milestone
audit/lifecycle only when requirements are actually met. No release or deployment.
