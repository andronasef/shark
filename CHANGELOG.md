# Changelog

All notable changes to the Shark file manager project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


### Changed
- Large drags use indexed ancestor checks and limit custom pile artwork to six items. Mounted rows and tabs share one middle-click event monitor.
- Photo viewers reuse their current image source and metadata; filmstrips use bounded cached thumbnails. A shared permit keeps full-image decoding serial across windows.
- Cascading folder menus load and sort off the main actor, share each popup listing, and prepare artwork in batches while preserving the 500-item cap.
- Thumbnail requests reuse 32-point size steps during zoom, keep valid artwork while replacements load, and avoid repeatedly shifting or filtering the scheduling queue.
- Directory filtering reuses sorted results and indexed selection; refreshes reject stale requests and coalesce filesystem events. Columns reuse the root listing and cancel obsolete loads.
- Folder Tree reuses its row projection, renders rows lazily, and restores remembered expanded descendants after hidden-file refreshes without reading collapsed branches.

### Fixed
- Folder-size results return to the requesting calculator. At most two scans run at once; clearing the cache cancels work and rejects late results.

## [1.0.0-alpha.2] - 2026-10-25

### Added
- The toolbar can show icons only or icons with labels (right-click the toolbar).
- View › Sort By, View › Share… and Edit › Find… (⌘F) keep sorting, sharing and filtering available even after their toolbar buttons are removed. ⌘F focuses the toolbar filter, or asks for the filter text when the search field isn't in the toolbar.
- Drag a favorite out of the sidebar and release it to remove the shortcut (the folder stays), as in Finder. Favorites drag as shortcuts, so reordering can never move the folder on disk.
- Sidebar style option: choose between Places (Finder-style Locations and Tags) and Folder Tree (Windows File Explorer-style collapsible folder hierarchy) in Settings › General › Sidebar. The folder tree lazily loads subfolders on demand, auto-reveals parent folders for the active location, supports full keyboard navigation (arrows, Return, Space), drag-and-drop file moves/copies, and item context menus.
- Shark Photo Viewer: a separate window for browsing images, opened from Open in Shark Photo Viewer in the item menu (View Selected Photos browses only the selection) or, if switched on in Settings › Previews, by double-clicking an image. Previous/next follow the folder's filtered and sorted order, with a thumbnail strip, fit and actual-size zoom, pinch/⌘± zoom and pan, view-only rotation, slideshow, full screen, an information line, and animated GIFs. JPEG, PNG, HEIC, TIFF and any other format macOS decodes; missing or damaged files show an explanation instead of failing. Space still opens Quick Look. Gallery view now shows real image previews.
- Item menus now include Open With (applications that can open every selected file, plus Other…), Share…, and a clearly named Shark Preview, grouped for opening, clipboard, renaming, paths and Trash. Opening more than 20 items asks first, and several folders open in separate tabs.
- Customize Toolbar… (also in the View menu): add, remove and reorder toolbar actions with the native macOS customization sheet. The layout is saved for all windows, Restore Defaults is built in, and narrow windows overflow natively.
- Shark is available in English, Arabic, Spanish, French, German, Brazilian Portuguese, Simplified Chinese and Japanese. Settings › General › Language offers System Default or an explicit language; Shark offers to restart right away to apply it (tabs are restored). Arabic text follows its own direction; window layout mirrors when macOS uses a right-to-left interface. File names, paths and the terminal keep their own direction.
- Terminal: ⌘+, ⌘− and ⌘0 change the terminal text size while it is focused (remembered, 8–36 pt), the drawer drags to resize from its top edge, and a shell that exits offers Restart.
- Help › Shark Help lists multi-selection drag, the optional image double-click, selection menus, and the terminal drawer.
- Website: a copyable Homebrew install command (`brew install --cask andronasef/shark/shark`) sits under the download buttons, and the install FAQ mentions it. The App Store review pill is shorter ("In review · day N"). README: download badges (latest release, Homebrew, Mac App Store, total downloads, macOS 14+) and a direct link to the Releases page.
- Shark is now licensed under the Apache License 2.0 (`LICENSE`).
- Website: the Mac App Store button shows how many days the app has been waiting for Apple’s review (since 20 Oct 2026) and previews the App Store Connect status on hover. Added a 1200×630 social share image, Open Graph and Twitter large-card tags, canonical and `SoftwareApplication` structured data, plus a generated `robots.txt` and sitemap (Astro plugins).
- Help › All Features opens the complete website feature catalog. The welcome’s feature step and Shark Help window also link to the full list.
- A three-step first-run welcome introduces Shark, highlights tabs, split panes, Quick Look, and the terminal, and offers optional setup for the default folder app and Full Disk Access. Skip it or reopen it from Help › Welcome to Shark. Settings › General can request Shark as the default folder app or restore Finder, with copyable manual setup commands when macOS rejects the APIs (restart required; availability varies by macOS version); Settings › Privacy links to Full Disk Access. Incoming folders reuse an open pane or open in a new tab, including when reopening Shark’s window. Finder-specific reveal actions still use Finder.
- Project links & feedback: added links to the Shark website (https://shark.andronasef.com/), source repository (https://github.com/andronasef/shark), feedback & feature request board (https://userhq.increasinglabs.com/increasing-labs/shark), and author credits for Andrew Nasef (https://andronasef.com/) across the Help menu, custom About panel, Settings › General, Help window, website navigation and footer, and documentation.
- Tagged releases now also build the sandboxed Mac App Store package and upload it to App Store Connect (skipped until the `APPSTORE_*` secrets are set; uses the notarization Apple ID). The upload lands as a build to select and submit for review; alpha tags upload as new builds of their base version (`v1.0.0-alpha.2` is another 1.0.0 build) numbered by the workflow run number.
- Update alerts: Shark checks for a newer version at launch (at most once a day) and from Shark › Check for Updates…, then offers the update route that matches how it was installed: Download for the DMG, Copy Command (`brew upgrade --cask shark`) for Homebrew, or Open App Store. The alert shows the release notes when the release has them. Skip a version, or turn automatic checks off in Settings › General. Shark never installs updates itself.

### Changed
- Right-click menus now show an icon beside each action (file and folder menus, folder background, tabs, tab groups, sidebar places, path bar, and the terminal's More menu), matching the icons already used in the toolbar's Action menu.
- The terminal no longer follows the folder you browse, which used to clear a partly typed command with Ctrl-U and type `cd` into the prompt. It starts in the active folder, keeps one shell per window across tabs, panes and hiding the drawer, and Use Current Folder now copies a quoted `cd` command to paste when you are ready.
- Closing a window with a running terminal command asks before ending it.
- Hover previews keep the image's whole aspect ratio instead of cropping extreme shapes, decode off the main thread at a bounded size, and cache by file revision and memory use.
- Directory thumbnails load with bounded concurrency, are reused only for the same file revision, size and display scale, cancel when scrolled away, and retry after a transient failure instead of caching a generic icon.
- The Location bar width is measured from the installed toolbar items instead of a fixed allowance.
- Release packaging (`scripts/package.sh`) and `scripts/run.sh` now bundle the localization resources. Menu items such as Undo and Redo use translatable text.
- Full Disk Access setup shows the running Shark app’s exact location and can reveal it in Finder, so development builds and duplicate installations are easier to add. Default-folder errors now distinguish a rejected one-click request from the separate restart-based manual option.
- Drops now follow Finder: they move within a disk and copy to another disk. Hold ⌥ to copy or ⌘ to move. Before, every drop moved, so dragging from an SD card or external drive removed the files from it.
- Every file operation can now be undone: Trash, drag-and-drop, duplicate, new folder and file, batch rename, and Compress join copy, move, and rename. Undoing something Shark created moves it to the Trash; nothing is permanently deleted.
- Multi-item operations (paste, drop, Trash, batch rename, copy) are all-or-nothing: if one item fails, the finished ones are put back. Failures show an alert instead of failing silently or replacing the folder view with an error page.
- Shark has a single window. ⌘N "New Window" is removed: extra windows mirrored the same tabs and panes, and the menus only drove the first one. Use tabs (⌘T) instead.
- Go › Desktop is now ⇧⌘D and Go › Documents ⇧⌘O, matching Finder. ⌥⌘D clashed with the system Dock shortcut.
- Back and Forward also work with ⌘[ and ⌘], as the toolbar tooltips already said. The terminal drawer also toggles with ⌃`, for keyboards where F4 opens Launchpad.
- Locked tabs can no longer be closed with ⌘W or a tab's close button, matching Close Other Tabs.
- The subfolder menu lists at most 500 items, with a final item that opens the folder, so huge folders no longer freeze the menu.
- Calculate Size recalculates on every request instead of showing a stale cached size.
- Removed the unused hardened-runtime exceptions (JIT, unsigned executable memory, disabled library validation) from the Developer ID build, and the `com.apple.security.inherit` entitlement, which is only for helper tools, from the App Store build.
- Refreshed marketing screenshots (README, website, App Store, Product Hunt) in dark mode with fuller demo content: a new tabs-and-split shot, a new terminal shot, and a list-view slide replacing the subfolder slide in the App Store and Product Hunt sets. Both sets have a new macOS-wallpaper style with shorter headlines and come from one generator, `scripts/generate-screenshots.swift`; `generate-producthunt.swift` is removed.

### Fixed
- Hover-preview timing tests wait for observable state with a deadline instead of assuming a busy CI executor resumes tasks within 140 ms. Manual release runs use the corrected hover tests against unchanged tagged app sources and skip repeat App Store uploads unless requested.
- Release CI now uses preinstalled Xcode 27.0 / Swift 6.4 for tests and both package jobs, matching the local toolchain instead of compiling with Xcode 16. The package declares its Swift 6.2 minimum for actor-isolated cleanup. A manual Release action can rebuild an existing tag with repaired CI settings without moving the tag.
- Directory status counts and selected-item summaries now use the chosen app language, including Arabic plurals.
- Reordering favorites by dragging works: the shortcut drag type is now declared in Info.plist, so the sidebar's drop gaps accept it. Releasing a favorite anywhere outside the sidebar removes it reliably.
- Folder Tree names cut off at the end instead of the middle, and nested folders indent slightly less, so deep names stay readable.
- Customize Toolbar names every item again (Location, Path, View, Group, Share, Split, Terminal, Action, Search) using SwiftUI's own labels, without the delegate hack that crashed.
- Photo viewer: a zoomed-in photo no longer spills over the file name, details line and thumbnail strip, and the window no longer shows a focus ring along its top edge.
- ⌘L and ⌘F now move the keyboard into the path field and the search field. Before, they showed or targeted the field but typing went nowhere while the sidebar had focus.
- Toolbar crashes: Shark no longer replaces SwiftUI's toolbar delegate or restyles AppKit's private toolbar and sheet views, which crashed item insertion and broke the Icon and Text layout. Both display modes use native item labels.
- Changing the language no longer restarts Shark without asking (which would end running terminal commands); it offers Restart Now or Later, and the restart waits for the old copy to quit.
- An open hover preview refits when a display is connected, disconnected, or resized.
- The folder-background menu now matches the item menu: with several folders selected, Open gives each its own tab instead of navigating one pane repeatedly. Every action has an icon and a translated label, and Show/Hide Hidden Files reflects the current state.
- Open With no longer looks up every selected file on the main thread when the menu opens (one cached query per file type), is hidden when folders are selected so it can't open them in an app, and says when no app can open all the files.
- Dragging a selected file now moves or copies the whole selection (icons, list, columns), not just one item; dragging an unselected item carries only that item. A batch move that cannot fully roll back after a failure now reports where the remaining items are.
- Terminal keys: with the terminal focused, arrow keys, history, Tab, Ctrl-C/D/Z and ⌘C/⌘V/⌘A go to the shell instead of the file list or file shortcuts, and clicking a file returns the keys to the files. Type-to-select and the other file shortcuts no longer fire in another window.
- Hover previews no longer extend below or beyond the screen: they flip to the other side of the pointer, shrink to fit, and recompute when content finishes loading, on secondary displays, or when displays change.
- Scrolling a large photo folder no longer decodes every image at once.
- A Sendable error in the hover preview thumbnail code that broke the build.
- Keep Navigation and Location together in one toolbar item to prevent independent placement across the sidebar boundary during launch.
- Multi-folder ZIP archives preserve each selected folder and files with the same name inside different folders.
- Undo and redo requests run one at a time; newer file actions invalidate pending redo history, and clearing history cannot be undone by an in-flight completion.
- **Data loss:** Cut (⌘X) and Paste (⌘V) into the same folder permanently deleted the file. Pasting a cut item over an existing name (including one that differs only by case) permanently deleted the existing item. Paste now never overwrites: a cut pasted back into its own folder does nothing, and a move onto an existing name is refused.
- **Data loss:** Undo after copy-pasting into a folder that already had the name deleted the *original* file rather than the "copy 1". Undo now removes exactly the items the copy made, and moves them to the Trash.
- **Data loss:** ⌘Z, ⌘X, ⌘C, ⌘V, ⌘A and ⌘⌫ ran file operations while typing in a text field (rename, search, path bar, command palette) or the terminal. For example, ⌘Z while renaming undid the last file operation, and ⌘⌫ to clear a name moved the file to the Trash. These shortcuts now edit the text, and ⌥←/⌥→/⌘↑ move the cursor instead of navigating.
- Select All followed by Move to Trash also trashed items hidden by the search filter. The selection now only ever contains visible items.
- Copying or moving a folder into itself or one of its subfolders is refused instead of failing halfway or recursing.
- Batch rename checked nothing up front, so a name collision part-way left some files renamed. It now rejects colliding or invalid names (`/`, `:`, `..`, over 255 bytes) before touching anything, supports swapping names, and is undoable.
- Rename and New Folder/File reject names containing `/` or `:` (a name like `../x` used to move the item out of the folder). Case-only renames (`readme` → `README`) work.
- Browsing the home folder (the default) caused a continuous reload loop: the folder watcher reacted to every change anywhere below the folder, and every reload rewrote Shark's own recents file. The watcher now reacts only to the folder's direct contents, and a visit is recorded once per arrival.
- A slow folder (for example on a network share) could replace the contents of a folder opened after it. Late results are now discarded, and navigation no longer loads each folder twice.
- A folder that is slow to list no longer stalls loading in every other pane and tab; listing is also cancelled when you navigate away. Each item needs one `lstat` instead of a full attribute lookup.
- Large folders no longer re-sort on every redraw and keypress; the sorted list is cached until the items, filter or sort change. The filter now ignores accents and case the way Finder search does.
- Shift-click ranges, arrow keys, Space (Quick Look), Share and the Inspector started from an arbitrary selected item. They now start from the last clicked item, and Quick Look and Share use the whole selection. ⌘-click and ⇧-click now work in list view.
- The embedded terminal typed its `cd` into whatever program was running (vim, python, psql). It now follows the folder only while the shell is at its prompt.
- Copy Path › POSIX Quoted Path used double quotes, so a file name containing `$(…)` or backticks ran a command when pasted into a shell. Paths are now single-quoted.
- The folder watcher could use a freed object if a pane closed while an event was being delivered, and raced on its callback.
- Session autosave no longer creates a security-scoped bookmark for every pane on every save, which made `bookmarks.json` grow without limit and slowed launch in the sandboxed build.
- Drag-and-drop no longer forces a move when the source app only allows copying (Safari, Photos, Mail).
- Compressing a large selection no longer blocks other file operations until the archive is done, and a failed archive leaves no partial ZIP behind.
- Compress now handles multiple selected items correctly; ditto previously rejected multiple archive sources.
- Compress can now be stopped: a stop button appears beside "Compressing…" in the status bar, and stopping removes the partial ZIP.
- The status bar's free-space reading and gallery icons no longer do disk or icon work on every redraw.
- Gallery and icon-view items are now VoiceOver buttons with the file name, kind, selection state, and an Open action.
- The terminal view no longer writes model state on every SwiftUI update.
- Removed the unused filter bar and compact list code.

## [1.0.0-alpha.1] - 2026-10-21

### Added
- Releases now include a signed, notarized `Shark-<version>.dmg` installer (drag Shark to Applications) in place of the ZIP, which is no longer published. The Homebrew cask now installs from the DMG.

## [1.0.0-alpha] - 2026-10-20

### Changed
- Calmer Location breadcrumbs: lighter, thinner separator chevrons, and the current folder is marked once (bold label on a neutral capsule) instead of also getting a blue folder icon.
- The sidebar hides iCloud Drive when it is switched off, as Finder does, instead of showing an item that fails with "Unable to open directory".
- `scripts/run.sh` builds with the InjectionIII flags (`-enable-implicit-dynamic`, `-interposable`) and signs with a stable `Shark Dev` certificate when present, so permission grants survive rebuilds.
- The toolbar Location capsule now starts directly beside Navigation and grows or shrinks with the window to fill the free toolbar space (minimum 160 pt) instead of stopping at 360 pt, so long paths are shown in full.
- Refined sidebar headings with hover feedback, keyboard focus outlines, arrow-key navigation, and temporary expansion during folder drags. Sidebar focus no longer triggers directory navigation shortcuts.
- Favorites now persist custom folders and order, support adding/reordering shortcuts with insertion guides, and offer Show in Finder, Locate Folder, and Remove from Favorites. Missing folders remain visible; removing a shortcut leaves its folder untouched. Ancestor indicators follow the active pane.
- Made sidebar sections collapsible with disclosure arrows, animated expansion, and remembered state; Reduce Motion disables transitions.
- Refined the top path capsule to fit short paths, use one menu chevron per segment, and show a neutral current-folder highlight. Long paths remain scrollable and editable.
- Moved Action after Split and Terminal, immediately before Search.
- Enlarged tabs to 28 pt within a 34 pt strip, increased label and close-button sizes, and added 200 ms open/close transitions with smooth width redistribution. Reduce Motion keeps changes immediate.
- Moved the breadcrumb path from the bottom of each directory pane into a glass Location capsule beside Back/Forward. Ancestor navigation, subfolder menus, path copying, and ⌘L editing remain available for the active pane.
- Corrected the tab strip to use equal-width, centered text tabs across the full available strip; removed unpinned folder icons and the inline Tab Groups control. Tab Groups remain on the add button’s context menu.
- Matched the toolbar and tabs to the supplied reference: capsule controls, captioned groups, a wider search field, and a full-width single-tab pill. Custom chrome uses native Liquid Glass on macOS 26+, with accessibility and older-system fallbacks; Split and Terminal buttons sit beside Action and highlight their active state.
- Matched the Places sidebar to the supplied reference with an inset rounded panel, larger monochrome icons, 32 pt rows, explicit section spacing, and brighter tag colors. Standard places now appear immediately while mounted volumes load.

### Fixed
- Corrected the Location capsule width allowance so it uses the available toolbar space with the sidebar shown or hidden, without pushing navigation into overflow at standard window widths.
- Fixed the toolbar pushing Back/Forward/Up (sidebar hidden) or Terminal/Action/Search (narrower windows) into the `»` overflow menu: the Location capsule is now sized with the real width the other toolbar items use, plus the traffic-light inset when the sidebar is collapsed.
- Fixed Shark freezing and consuming tens of GB of memory when navigating to the disk root (e.g. clicking "Macintosh HD" in the path bar). The path bar now builds its folder chain from path components, which always ends at `/`.
- Back, Forward, Up, and the tab close button now respond to clicks anywhere on the button, not only on the icon.
- Hover previews now show the whole image instead of a zoomed crop, and very tall or wide images (page screenshots, banners) show a square view of their start rather than a thin sliver.
- Long file names in the "Compress" context-menu item are now shortened in the middle, keeping the start and extension, so the menu stays compact.
- Text hover previews no longer fail when the first read ends mid-character, binary files are no longer previewed as text, and edited files no longer show a stale cached preview.
- Folders blocked by macOS privacy protection (e.g. Trash) now explain why and offer a button that opens Full Disk Access settings, instead of only "Try Again".

### Added
- **Firebase Analytics & Crashlytics Telemetry**:
  - Integrated `FirebaseAnalytics` and `FirebaseCrashlytics` from `firebase-ios-sdk` (11.0.0+).
  - Telemetry is enabled by default with independent user controls in Settings › Privacy (`Share anonymous usage statistics` and `Send crash reports`).
  - Privacy-preserving architecture: safe anonymous events only (`app_launch`, `tab_opened`, `tab_closed`, `view_mode_changed`, `split_view_toggled`, `terminal_toggled`). Absolutely no filenames, folder paths, file contents, or shell command arguments are captured.
  - Safe headless and test initialization verifying bundle plist presence before configuring.
  - Automated release `dSYM` symbol extraction via `dsymutil` into `dist/Shark.app.dSYM` during packaging, with optional Crashlytics upload via `scripts/upload-symbols.sh` (`UPLOAD_CRASHLYTICS_SYMBOLS=1`).
- A complete website Features page with a categorized app capability catalog, shared site navigation, and an `AGENTS.md` rule requiring feature changes to update the catalog in the same change.
- An Astro landing page in `website/` with real product screenshots, restrained glass navigation, responsive feature stories, installation FAQs, and free macOS download links.
- A getting-started README with screenshots of tabs and split panes, the terminal drawer, hover previews, and cascading subfolder menus.
- Release preparation: universal app packaging, a tag-triggered Developer ID signing and notarization workflow with checksums, and publishing guidance covering GitHub setup and Mac App Store sandbox prerequisites.
- **Mouse actions** (each can be turned off in Settings › Mouse): double-click empty space in a folder to go up one level (icon and details views); double-click a tab to pin or unpin it; scroll the wheel over the tab strip to cycle tabs; mouse side buttons go back and forward, and ⌃ + side button switches tabs.
- **Shark Help** window (Help › Shark Help, ⌘?) listing what the mouse does in each zone: folder empty space, items, tabs, the tab strip, sidebar and path bar, and anywhere.
- **Subfolder tip**: hovering a folder in the list or icon view now reveals a drop-down arrow (beside the name in the list, in the top-right corner of the icon cell in the icon view). Clicking it opens a cascading menu of everything inside, to any depth; click an item to open it, ⌘-click to open a folder in a new tab, or ⌥-click to copy it (⌘V pastes). It can be turned off in Settings › Previews.
- **Deeper hover previews**: previews now appear in a non-activating floating panel so keyboard focus stays where it was, and the pointer can move into the panel to use its controls. Video and audio play inline with a seek bar (auto-play is optional), animated GIFs animate, images show at full resolution, text shows up to 40 lines with its detected encoding, and Office/iWork/RTF/PDF documents show a thumbnail. New settings: preview only while holding Shift, and auto-play media.
- **Liquid Glass adoption plan**: Documented proposed native Finder-style chrome, macOS 14/15 fallback, accessibility behavior, and visual acceptance checks. Implementation is pending.
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Native Finder Design Alignment**:
  - Authentically aligned window layout, navigation bar, and icon grid with macOS Finder.
  - Leading navigation group featuring Back/Forward navigation history buttons alongside the active folder's system icon and title.
  - Flexible center space (`.principal Spacer`) distributing action controls cleanly to the trailing edge of the window toolbar.
  - Discrete popovers for **Path Hierarchy**, **Group & Sort**, and **Action Menu**, replacing default `Menu` items to eliminate AppKit disclosure triangles and button clipping.
  - Segmented View Mode control (`[ ⊞ | ≣ | ☷ | 🗔 ]`) with intrinsic 176pt width and balanced padding to prevent control overlaps.
  - Finder-styled sub-toolbar single-tab capsule displaying centered active folder name and `+` button.
  - macOS Places sidebar structured into *Recents*, *Shared*, *Favorites*, *Locations*, and *Tags*.
- **SwiftTerm Terminal Emulation**:
  - Integrated `SwiftTerm` (`SwiftTermView`) replacing raw text terminal views.
  - Full VT100/xterm ANSI escape sequence rendering, cursor management, and keyboard handling.
  - Bidirectional directory sync between active file browser navigation and the embedded terminal session.
- **Developer Hot Reload**:
  - Integrated `Inject` package for runtime SwiftUI view injection.
  - Added `@ObserveInjection` and `.enableInjection()` across key views (`ContentView`, `PlacesSidebarView`, `DirectoryView`, `IconsGridView`, `TabBarView`).
  - Added standalone development runner [`scripts/dev.sh`](scripts/dev.sh) and python file watcher [`scripts/hot_reload.py`](scripts/hot_reload.py).

### Fixed
- Connected the hover-preview setting and delay to file items in grid, list, column, and gallery views. Leaving an item, renaming, or disabling previews cancels pending previews.
- Stopped directory type-to-select and column navigation from consuming keystrokes while the embedded terminal has focus.
- Restored a visible Up button beside Back and Forward, navigating to the active pane’s parent folder.
- Fixed “Open in Terminal” on folder, background, and breadcrumb menus to explicitly launch Terminal.app rather than Finder. Added “Open in Embedded Terminal” at the clicked directory; files use their parent folder.
- Fixed the Terminal button and F4 failing to redraw the drawer by restoring observation of terminal visibility.
- Fixed split-pane focus: clicking or scrolling either pane now activates it before child controls handle input. Only the active pane registers navigation shortcuts, and inactive column views no longer intercept arrow keys.
- Made middle-click tab closing use the actual pointer position instead of a stale global hover target, scoped to the clicked window and visible tab region.
- Fixed Command + scroll wheel icon resizing by intercepting scroll events within the hovered directory pane without blocking normal clicks or scrolling.
- Fixed top bar overlap where the View segmented control collided with the Path button.
- Fixed duplicated button titles and unwanted `⌵` chevrons drawn by AppKit's `NSMenuToolbarItem`.
- Fixed window toolbar layout packing all items against the left side rather than trailing right.
- Fixed root traversal hanging and `NSTextView` designated initializer crash in earlier terminal integration.

---

## [0.6.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **File Operations Engine**:
  - New Folder and New File creation with automatic naming collision resolution (`Folder`, `Folder 2`, etc.).
  - Duplicate item functionality (`⌘D`) appending "copy" or incrementing counters.
  - Move to Trash (`⌘⌫`) with system trash integration.
  - Drag-and-drop file movement between split panes and external apps.
  - Batch Rename tool with Find/Replace, Prefix/Suffix, numbering, and case conversions.
  - Real-time directory monitoring via `FSEvents` stream.

---

## [0.5.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Information & Metadata Inspector**:
  - Right-side collapsible Inspector panel (`⌥⌘I`).
  - POSIX file permissions display and octal representation (e.g. `0755` / `rwxr-xr-x`).
  - Asynchronous SHA-256 cryptographic checksum calculation with copy-to-clipboard.
  - File size formatting, item count for directories, creation and modification timestamps.

---

## [0.4.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Embedded Terminal Drawer**:
  - Collapsible bottom terminal drawer toggled via `F4` or toolbar button.
  - PTY pseudo-terminal session running user shell (`$SHELL`).
  - Directory synchronization tracking file navigation.

---

## [0.3.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **View Modes & Quick Look**:
  - Icons grid view (`⌘1`), Details list view (`⌘2`), Compact columns (`⌘3`), and Gallery (`⌘4`).
  - Instant live filename filtering (`⌘I`).
  - Quick Look integration with macOS `QLPreviewPanel` on Spacebar press.

---

## [0.2.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- **Dual-Pane Split & Tabbed Browsing**:
  - Split view support (`⇧⌘S`) for dual-pane file management inspired by KDE Dolphin.
  - Tab management (`⌘T` new tab, `⌘W` close tab).

---

## [0.1.0] - 2026-10-13

### Added
- **App Icon**: Shark mascot icon (`Resources/AppIcon.png`), compiled to `AppIcon.icns` into the bundle by `scripts/make-icon.sh` (run automatically by `scripts/run.sh`).
- Initial project foundation in native Swift and SwiftUI.
- Filesystem enumeration, volume detection, and navigation state.
- Standard macOS sidebar places and directory listing.
