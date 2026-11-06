# Shark roadmap

All three groups below were authorized for autonomous implementation on 2026-11-06. They are plans, not a list of available features. The implemented public inventory is `website/src/data/features.ts`; the execution roadmap is `.planning/ROADMAP.md`, with exact requirements in `.planning/REQUIREMENTS.md` and full decisions in `.planning/EVERYDAY-MAC-MILESTONE.md`.

The internal GSD milestone is **v2.1 Everyday Mac Workflows**, phases **12–31**. That number does not change the public app version. Each feature or fix gets its own conventional commit and its Help, public catalog, changelog, changed design rules and verification. No release, deployment or App Store submission is requested.

## Product direction

Power users remain first; everyday Mac users moving off Finder are a second audience. Match Finder's daily capabilities as a minimum and keep the native Finder appearance. macOS mounts remote servers; Shark then browses their volumes. Other applications' Open/Save dialogs remain the system interface. Use public native APIs, keep disk work off the main thread, and preserve originals through Trash or undo.

## Group 1 — everyday essentials

Implementation order follows dependencies: honest Tags patch → collisions → extraction → Trash → extension warnings → iCloud → search → real tags.

| Phase | Capability | Agreed behavior |
|-------|------------|-----------------|
| 12 | Honest sidebar | Hide fake Tags/color-name filters and empty All Tags; remove keyboard stops until real tags land. Explain system Open/Save limits in Help, welcome and FAQ. |
| 13 | Collision choices | One thumbnail/size/date comparison dialog for copy/move/paste/drop: Replace / Keep Both / Skip / Stop, compatible Apply to all, and recursive folder Merge. Replace trashes the destination and is undoable. Keep Both uses numeric suffixes; Duplicate keeps "copy". |
| 14 | Extract | Context-menu extraction beside the archive, one item directly or several in an archive-named folder. Shared collision choices, safe staging/path/link handling, native tools and Archive Utility fallback. Double-click still uses the default app. |
| 15 | Trash | Persist Shark's original/Trash locations for Put Back after relaunch. Use shared collisions, prune stale records safely, and offer Show in Finder for unknown originals. Empty Trash confirms irreversibility and delegates to Finder, with denial fallback and applicable App Review notes. |
| 16 | Extension warning | Always show extensions; ask Keep old / Use new extension when rename changes/removes it, including inline and other rename paths. Handle folders and dotfiles sensibly. |
| 17 | iCloud | Accurate cloud-only/downloading/uploading/error/shared badges, quiet synced files, Download Now / Remove Download and download-before-open. Public metadata only, no invented progress. |
| 18 | Search | Existing Cmd-F filter with This Folder / Subfolders / This Mac and Name only. Option-Cmd-F chooses This Mac. Live uncapped Spotlight name/content results, best-match default plus normal sort, source-path display, history/Back/Escape, real file actions. Cancellable name-walk fallback on unindexed volumes. |
| 19 | Finder tags | Real tag metadata, color dots/custom Tags, inspector and multi-selection edits, actual sidebar tag queries. Dots trail list/column names and sit below icon/gallery names, three plus +N. Optional sortable Tags column starts off. |

## Group 2 — expected Mac workflows

| Phase | Capability | Agreed behavior |
|-------|------------|-----------------|
| 20 | Recents and places | Spotlight files used in the last 30 days, newest first, as a result location. Default Recents, Applications, Desktop, Documents, Downloads, available iCloud Drive and Network, individually hideable in Settings. Preserve favorites/tree/eject. AirDrop is sharing, not a fake directory. |
| 21 | Transfer controls | After about two seconds, status-bar speed/time remaining and clickable operation list with Pause/Resume/Cancel. Cancel cleans partial output and preserves originals and completed work. |
| 22 | References | Make Alias creates a real macOS alias as "name alias". Option shows Make Symbolic Link instead. Both use safe collision naming. |
| 23 | Spring loading | Drag-hover folders, tabs and path segments opens after the system delay; Space opens immediately. Respect system preferences and cancel navigation when drag leaves/ends. |
| 24 | Get Info | Single-item Open with, confirmed Change All, Comments and Locked. Multi-item count/size/kinds and batch tags/Open with, with accurate failures. |
| 25 | Connect to Server | Native Go-menu address/recent-server window; validate smb/afp/nfs URLs and hand mounting to macOS. Store no credentials. Existing volume notifications populate the sidebar. |

## Group 3 — native actions and organization

Earlier deferral was superseded by the user's explicit request for all three groups. Use restrained native defaults and document detailed choices in phase context/design contracts.

| Phase | Capability | Default direction |
|-------|------------|-------------------|
| 26 | Quick Actions | Working Rotate, Convert Image, Create PDF and Markup for applicable selections. Preserve originals for derivatives, safely name output, and use explicit Markup in Preview if a supported native in-app surface is unavailable. |
| 27 | Group By | Kind / Date / None in list and icon views; useful stable headers, within-group sorting, selection/keyboard behavior matching visible order and responsive large folders. |
| 28 | Smart Folders | Save and persist query, scope, Name only and name; reopen live from sidebar; rename/remove definitions without deleting matching files. No unimplemented Finder .savedSearch compatibility claims. |
| 29 | AirDrop | Direct context-menu NSSharingService action with normal receiver selection and accurate availability. |
| 30 | Print | Cmd-P and discoverable native printing or explicitly labeled app handoff for supported documents; respect other active responders. |
| 31 | Services | Real system Services menu, selected URL pasteboard/responder support, accurate focus/selection availability. |

## Verification and finish

Tests cover non-trivial logic and safe failure paths. Check changed native UI in the running app; build/test alone does not prove layout or interaction. Run the website build and inspect the features page at desktop/mobile sizes when its catalog changes. Public inventory gains only verified implemented capabilities. Never script system privacy prompts or irreversibly test against real user files/Trash. Record account/system/human-validation limits honestly. After phases pass, run the GSD requirement/integration audit and completion/archive/cleanup lifecycle; no release is implied.
