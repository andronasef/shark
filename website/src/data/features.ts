/**
 * Public inventory of implemented, user-facing Shark capabilities.
 * Keep this catalog current in the same change as app features (see AGENTS.md).
 * Source notes below are for maintainers; they are not rendered on the page.
 */
export interface Feature {
  id: string;
  title: string;
  description: string;
  shortcut?: string;
}

export interface FeatureGroup {
  id: string;
  title: string;
  description: string;
  features: Feature[];
}

export const featureGroups: FeatureGroup[] = [
  // WorkspaceState, SessionStore, TabGroupService, TabItemView, SharkApp.TabCommands.
  {
    id: 'workspace', title: 'Tabs & workspace',
    description: 'Keep your folders together, and your next task close by.',
    features: [
      { id: 'folder-tabs', title: 'Folder tabs', description: 'Open folders in separate tabs, duplicate a tab, and close one, the others, or everything to its right.', shortcut: '⌘T' },
      { id: 'split-panes', title: 'Side-by-side panes', description: 'Browse two locations in one tab. Each pane keeps its own folder and view, and file actions follow the active pane.', shortcut: 'F3' },
      { id: 'tab-organization', title: 'Reorder, pin, lock & color', description: 'Drag tabs into order, pin frequently used folders, lock a tab so its location stays put and it can’t be closed by accident, and choose a color to distinguish it.' },
      { id: 'reopen-tabs', title: 'Reopen closed tabs', description: 'Bring back a closed tab or choose one from the Recently Closed menu.', shortcut: '⇧⌘T' },
      { id: 'tab-groups', title: 'Saved tab groups', description: 'Save a set of tabs as a named group. Restore it as your workspace or append it to your open tabs.' },
      { id: 'session-restore', title: 'Session restore', description: 'Return to your saved tabs and pane layout when you reopen Shark.' },
      { id: 'tab-navigation', title: 'Keyboard tab switching', description: 'Cycle through tabs with Control-Tab and Control-Shift-Tab, or jump to a tab with Option-Command and a number.' },
    ],
  },
  // NavigationState, CommandPaletteService, RecentFoldersService, PlacesSidebarView, PathBarView.
  {
    id: 'navigation', title: 'Navigation & finding',
    description: 'A direct route to a folder, a file, or the action you need.',
    features: [
      { id: 'editable-path', title: 'Editable folder paths', description: 'Click through ancestor folders in the location bar or type a path to go directly to a location. Show or hide the path bar from the View menu.', shortcut: '⌘L' },
      { id: 'folder-history', title: 'Back, forward & up', description: 'Retrace your folder history with Command-[ and Command-] (or Option-Left and Option-Right), or go to the enclosing folder with Command-Up.' },
      { id: 'command-palette', title: 'Command palette', description: 'Find actions, common places, recent and frequent folders, saved tab groups, and paths from one keyboard-driven panel.', shortcut: '⌘K' },
      { id: 'instant-filter', title: 'Instant filename filtering', description: 'Narrow the current folder by typing in the toolbar’s search field. Filtering ignores case and accents, and hidden results leave the selection so file actions only affect visible items.' },
      { id: 'type-to-select', title: 'Type to select', description: 'Type a filename to move the selection to a matching item without changing the folder.' },
      { id: 'favorites', title: 'Persistent favorites', description: 'Add and reorder folder shortcuts in the sidebar. Remove a shortcut without deleting the folder, or relocate it if its target moves.' },
      { id: 'sidebar-sections', title: 'Collapsible sidebar sections', description: 'Keep the sections you use open. Expansion is remembered, headings support the keyboard, and collapsed sections can open temporarily during a drag.' },
      { id: 'recent-frequent', title: 'Recent & frequent folders', description: 'Revisit your working locations from the Go menu or the command palette.' },
      { id: 'subfolder-menus', title: 'Cascading subfolder menus', description: 'Use the arrow on a hovered folder or path segment to browse nested folders. Click to open, Command-click a folder for a new tab, or Option-click to copy. Switch the hovered-folder arrow off in Settings › Previews.' },
      { id: 'local-volumes', title: 'Local folders & mounted volumes', description: 'Browse your Mac and volumes mounted in macOS from the sidebar. Shark does not include a built-in remote-protocol or cloud-account client.' },
    ],
  },
  // ViewMode, DetailsTableView, MillerColumnsView, IconsGridView, GalleryView, NavigationState.
  {
    id: 'views', title: 'Views & organization',
    description: 'See your files in the form that makes the most sense.',
    features: [
      { id: 'icon-view', title: 'Icon view', description: 'Browse a grid of folders and file thumbnails with adjustable icon sizes and drag selection.', shortcut: '⌘1' },
      { id: 'list-view', title: 'List view', description: 'Compare names, modified dates, sizes, kinds, and permissions in a sortable details table. Command-click toggles items and Shift-click selects a range from the last clicked item.', shortcut: '⌘2' },
      { id: 'column-view', title: 'Column view', description: 'Follow a folder hierarchy across cascading columns, with arrow-key navigation, a preview, and file details at the end.', shortcut: '⌘3' },
      { id: 'gallery-view', title: 'Gallery view', description: 'Give the selected file a large preview while keeping a thumbnail strip in reach.', shortcut: '⌘4' },
      { id: 'icon-zoom', title: 'Adjustable icon zoom', description: 'Make icons larger or smaller with Command-plus, Command-minus, or Command-scroll. Command-0 restores the default size.' },
      { id: 'sorting', title: 'Sorting controls', description: 'Sort by name, modified date, size, kind, or permissions, and switch between ascending and descending order.' },
      { id: 'hidden-files', title: 'Hidden files & dotfiles', description: 'Show or hide dotfiles and other hidden items in the folder you are browsing.', shortcut: '⇧⌘.' },
      { id: 'live-updates', title: 'Live folder updates', description: 'The file list updates as the contents of the folder change.' },
      { id: 'status-bar', title: 'Folder & selection status', description: 'See item counts, filtered results, the selected items’ total size, and available disk space in the status bar.' },
    ],
  },
  // HoverPreviewService, FileHoverPreview, HoverPreviewPanel, SettingsView.previewsTab, ContentView.
  {
    id: 'previews', title: 'Previews & Quick Look',
    description: 'Look inside a file before you decide what comes next.',
    features: [
      { id: 'quick-look', title: 'macOS Quick Look', description: 'Preview selected files using the Mac’s built-in Quick Look.', shortcut: 'Space' },
      { id: 'image-previews', title: 'Image & animated image previews', description: 'Hover over an image to see it in a floating preview, including animated images.' },
      { id: 'text-previews', title: 'Text file previews', description: 'Read up to 40 lines of a text file on hover, with support for UTF-8, UTF-16, and Latin-1 text.' },
      { id: 'document-previews', title: 'Document thumbnails', description: 'See available document thumbnails, including PDF, Office, iWork, and RTF files.' },
      { id: 'media-previews', title: 'Video & audio playback', description: 'Play media in the hover preview with playback and seek controls. Move the pointer into the preview to use them.' },
      { id: 'preview-preferences', title: 'Previews on your terms', description: 'Adjust the hover delay, require holding Shift, choose media autoplay, or switch hover previews off in Settings.' },
    ],
  },
  // FileOperationsService, FileClipboardService, FileUndoService, BatchRenameSheet, DirectoryView.
  {
    id: 'file-operations', title: 'Everyday file operations',
    description: 'The familiar essentials, with room for the bigger jobs.',
    features: [
      { id: 'new-items', title: 'New folders & files', description: 'Create a folder or a new file directly in the location you are browsing. Command-Shift-N creates a folder.' },
      { id: 'clipboard', title: 'Cut, copy & paste', description: 'Use Command-X, Command-C, and Command-V to move or copy files between folders. Cut items are dimmed so you can see what is ready to move. Pasting never replaces an existing item: copies get a “copy” name, and a move onto an existing name is refused. In text fields, these keys edit the text as usual.' },
      { id: 'drag-drop', title: 'Drag & drop', description: 'Move files between panes or into folders. Like Finder, a drop moves within a disk and copies to another disk. Hold Option to copy or Command to move.' },
      { id: 'rename', title: 'Inline rename', description: 'Change a file or folder name in place.', shortcut: 'F2' },
      { id: 'batch-rename', title: 'Batch rename with a preview', description: 'Find and replace text, add a prefix or suffix, or apply sequential numbering to a selection. Review the new names before applying them. Shark renames all items or none, and refuses names that collide or contain “/” or “:”.' },
      { id: 'duplicate', title: 'Duplicate files', description: 'Create another copy of selected items in the same folder.' },
      { id: 'compress', title: 'ZIP compression', description: 'Create a ZIP archive from the selected files and folders. Stop a long one from the status bar.' },
      { id: 'trash', title: 'Move to Trash', description: 'Send selected items to the macOS Trash.', shortcut: '⌘⌫' },
      { id: 'undo-redo', title: 'Undo & redo', description: 'Undo and redo moves, copies, duplicates, new folders and files, renames (including batch renames), ZIP archives, and Trash with Command-Z and Command-Shift-Z. Undoing a copy moves the copy to the Trash.' },
      { id: 'copy-path', title: 'Copy file & folder paths', description: 'Copy a full, relative, or quoted path from the item menu, or copy the active tab’s folder path.' },
      { id: 'show-in-finder', title: 'Show in Finder', description: 'Reveal selected items or a sidebar favorite in Finder whenever you want to switch to the system file browser.' },
      { id: 'sharing', title: 'Native sharing', description: 'Send selected files through the macOS sharing menu using the Share button.' },
    ],
  },
  // TerminalDrawerView, PTYSession, TerminalSessionManager, InspectorPanelView, FileMetadataService.
  {
    id: 'terminal-inspector', title: 'Terminal & inspection',
    description: 'Work with your files, and see what is behind them.',
    features: [
      { id: 'terminal-drawer', title: 'Built-in terminal', description: 'Open a real interactive terminal beneath your files, with shell input and terminal output in the same window. Control-` also toggles it, for keyboards where F4 opens Launchpad.', shortcut: 'F4' },
      { id: 'terminal-sync', title: 'Folder-aware terminal', description: 'The embedded terminal follows the active folder while the shell is at its prompt. It never types into a program that is running, such as an editor.' },
      { id: 'external-terminal', title: 'Open in Terminal', description: 'Open the chosen folder in macOS Terminal, or choose Open in Embedded Terminal to work inside Shark.' },
      { id: 'file-inspector', title: 'File inspector', description: 'Inspect the selected item’s location, size, dates, kind, and owner, group, and POSIX permissions.', shortcut: '⌥⌘I' },
      { id: 'image-dimensions', title: 'Image dimensions', description: 'Check the pixel dimensions of supported images in the inspector.' },
      { id: 'folder-sizes', title: 'On-demand folder sizes', description: 'Calculate the size of an individual folder from its context menu, or calculate all folder sizes using the command palette.' },
      { id: 'checksums', title: 'SHA-256 checksums', description: 'Calculate a file’s SHA-256 checksum on demand and copy the result.' },
    ],
  },
  // MouseHelp.zones in HelpView.swift is authoritative for bindings; MouseSettings.swift owns switches.
  {
    id: 'mouse', title: 'Mouse & trackpad',
    description: 'Useful shortcuts wherever your pointer happens to be.',
    features: [
      { id: 'empty-space', title: 'Folder background actions', description: 'Click empty space to clear the selection, drag a selection rectangle in icon view, or double-click empty space to go up one level.' },
      { id: 'item-actions', title: 'Open & act on items', description: 'Double-click to open a file or folder, and right-click for item actions. Right-click the folder background for creation, paste, reload, terminal, hidden-file, and path actions.' },
      { id: 'middle-click', title: 'Middle-click navigation', description: 'Middle-click a folder, sidebar place, or path segment to open it in a new tab. Middle-click a tab to close it.' },
      { id: 'tab-mouse', title: 'Tab gestures', description: 'Click to switch, double-click to pin or unpin, drag to reorder, and right-click for tab actions. Right-click the plus button for Tab Groups.' },
      { id: 'wheel-tabs', title: 'Scroll through tabs', description: 'Scroll the wheel over the tab strip: down selects the next tab, up selects the previous one.' },
      { id: 'side-buttons', title: 'Mouse side buttons', description: 'Use back and forward buttons for folder history. Hold Control to switch to the previous or next tab instead.' },
      { id: 'path-mouse', title: 'Path bar shortcuts', description: 'Command-click an ancestor path segment to open it in a new tab, or click its arrow to browse subfolders.' },
      { id: 'mouse-preferences', title: 'Optional gestures & in-app help', description: 'Switch optional background, tab, wheel, and side-button actions on or off in Settings › Mouse. Help › Shark Help lists the bindings by pointer location.' },
    ],
  },
  // SharkSettings, SettingsView, FinderChromeView, SecurityScopedBookmarkManager, DirectoryStateViews, UpdateChecker.
  // Omit startup/view-default and tab-preference controls until their stored settings drive app behavior.
  {
    id: 'mac-settings', title: 'Mac appearance & preferences',
    description: 'A native place for your files, with the choices left to you.',
    features: [
      { id: 'native-materials', title: 'Native Mac materials', description: 'Liquid Glass chrome on macOS 26, with system material fallbacks on macOS 14 and 15. Translucency can be turned off in Settings.' },
      { id: 'appearance', title: 'Light & dark appearance', description: 'The app follows your Mac’s appearance and uses native controls and system colors.' },
      { id: 'accessibility', title: 'Accessible controls & motion', description: 'Labeled controls, keyboard navigation, and support for Reduce Motion, Reduce Transparency, and increased contrast.' },
      { id: 'folder-permissions', title: 'macOS folder access', description: 'Grant access to protected folders when macOS asks. When privacy settings block a location, Shark offers guidance and a route to the relevant settings.' },
      { id: 'privacy-telemetry', title: 'Privacy & diagnostics', description: 'Anonymous usage statistics and crash reporting are on by default and can be independently turned off in Settings › Privacy. File names, folder paths, and terminal commands are never collected.' },
      { id: 'update-alerts', title: 'Update alerts', description: 'Shark checks for a new version once a day and from Shark › Check for Updates…. The alert points DMG installs to the download, Homebrew installs to brew upgrade --cask shark, and Mac App Store installs to the App Store, with the release notes when available. Choose Skip This Version, or turn automatic checks off in Settings › General.' },
      { id: 'about-feedback', title: 'Help, website & feedback', description: 'Quickly reach the website, source repository, feedback board, and author details from the Help menu, About panel, and Settings › General.' },
    ],
  },
];
