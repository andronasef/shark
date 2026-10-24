import SwiftUI
import AppKit
import SwiftTerm

public struct DirectoryView: View {
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let pane: PaneIdentifier

    @State private var owningWindowNumber: Int?
    @State private var fseventsWatcher = FSEventsWatcher()
    @State private var showingNewItemSheet: NewItemType? = nil
    @State private var showingBatchRenameSheet: Bool = false
    @State private var contextRenameItems: [FileItem]?
    @State private var previewItem: FileItem? = nil
    @State private var lastClickedURL: URL? = nil
    @State private var lastClickTime: TimeInterval = 0
    @State private var typeToSelectMonitor: Any? = nil
    @State private var diskSpaceSummary: String? = nil

    public init(
        navigationState: NavigationState,
        pane: PaneIdentifier = .primary
    ) {
        self.navigationState = navigationState
        self.pane = pane
    }

    public var body: some View {
        VStack(spacing: 0) {
            contentArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .dropDestination(for: URL.self) { urls, _ in
                    let modifiers = NSEvent.modifierFlags
                    let destination = navigationState.currentURL
                    Task { await navigationState.drop(urls, into: destination, modifiers: modifiers) }
                    return true
                }
                .onCommandScrollZoom { delta in
                    navigationState.adjustZoom(delta: delta)
                }

            statusBar
        }
        .task(id: navigationState.currentURL) {
            await navigationState.reloadCurrentDirectory()
            setupFSEventsWatcher()
            let url = navigationState.currentURL
            // Volume capacity can block on network volumes, so it is read once per folder, off main.
            diskSpaceSummary = await Task.detached { DiskSpaceService.shared.getDiskSpace(for: url)?.summary }.value
        }
        .alert(
            "The operation couldn’t be completed",
            isPresented: Binding(
                get: { navigationState.operationError != nil },
                set: { if !$0 { navigationState.operationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(navigationState.operationError ?? "")
        }
        .background(WindowNumberReader { owningWindowNumber = $0 })
        .onAppear {
            if typeToSelectMonitor == nil {
                typeToSelectMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    guard event.windowNumber == owningWindowNumber else { return event }
                    if workspace?.sidebarHasKeyboardFocus == true { return event }
                    if let ws = workspace, ws.activeNavigationState !== navigationState {
                        return event
                    }
                    guard let window = event.window,
                          !(window.firstResponder is NSTextView),
                          !(window.firstResponder is NSTextField),
                          !(window.firstResponder is SwiftTerm.TerminalView) else {
                        return event
                    }
                    guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else {
                        return event
                    }
                    if let ws = workspace, ws.isCommandPalettePresented {
                        return event
                    }

                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    if flags.isEmpty || flags == .shift {
                        if let chars = event.characters, let firstChar = chars.first, !firstChar.isWhitespace && !firstChar.isNewline {
                            TypeToSelectCoordinator.shared.appendCharacter(firstChar, in: navigationState)
                            return nil
                        }
                    }
                    return event
                }
            }
        }
        .onDisappear {
            fseventsWatcher.stop()
            if let monitor = typeToSelectMonitor {
                NSEvent.removeMonitor(monitor)
                typeToSelectMonitor = nil
            }
        }
        .popover(item: $previewItem, arrowEdge: .trailing) { item in
            HoverPreviewCard(item: item)
                .padding(4)
        }
        .sheet(item: $showingNewItemSheet) { itemType in
            NewItemSheet(
                type: itemType,
                parentURL: navigationState.currentURL,
                onCreated: {
                    Task { await navigationState.reloadCurrentDirectory() }
                }
            )
        }
        .sheet(isPresented: $showingBatchRenameSheet, onDismiss: { contextRenameItems = nil }) {
            let selectedItems = contextRenameItems ?? navigationState.items.filter { navigationState.selectedItemIDs.contains($0.id) }
            BatchRenameSheet(
                items: selectedItems,
                onRenameComplete: {
                    Task { await navigationState.reloadCurrentDirectory() }
                }
            )
        }
        .contextMenu {
            directoryBackgroundContextMenu
        }
        .background {
            // Only the active pane registers shortcuts. An inactive pane must
            // not win SwiftUI's duplicate-key-equivalent lookup.
            if !TerminalKeyboardOwnership.shared.isFocused(in: NSApp.keyWindow) && workspace?.sidebarHasKeyboardFocus != true && (workspace == nil || workspace?.activeNavigationState === navigationState) {
                // Local fallback keyboard shortcuts for instant responsiveness
                Group {
                    Button("") { navigationState.zoomIn() }
                        .keyboardShortcut("+", modifiers: .command)
                    Button("") { navigationState.zoomIn() }
                        .keyboardShortcut("=", modifiers: .command)
                    Button("") { navigationState.zoomOut() }
                        .keyboardShortcut("-", modifiers: .command)
                    Button("") { navigationState.resetZoom() }
                        .keyboardShortcut("0", modifiers: .command)

                    // Windows Explorer Alt Navigation Shortcuts
                    Button("") { navigationState.goBack() }
                        .keyboardShortcut(.leftArrow, modifiers: .option)
                    Button("") { navigationState.goForward() }
                        .keyboardShortcut(.rightArrow, modifiers: .option)
                    Button("") { navigationState.goUp() }
                        .keyboardShortcut(.upArrow, modifiers: .option)
                    Button("") { navigationState.isEditingPath = true }
                        .keyboardShortcut("d", modifiers: .option)

                    // Arrow Key Item Navigation (Windows Explorer & Finder)
                    // Up / Down moves up and down row-by-row in both Grid and List views
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if navigationState.viewMode == .grid {
                            navigationState.selectAboveItem()
                        } else {
                            navigationState.selectAboveItem(approximateColumns: 1)
                        }
                    }
                    .keyboardShortcut(.upArrow, modifiers: [])

                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if navigationState.viewMode == .grid {
                            navigationState.selectBelowItem()
                        } else {
                            navigationState.selectBelowItem(approximateColumns: 1)
                        }
                    }
                    .keyboardShortcut(.downArrow, modifiers: [])

                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        navigationState.selectPreviousItem()
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])

                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        navigationState.selectNextItem()
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])

                    // Return starts inline rename (Finder standard, CMD-03)
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if let firstSelected = navigationState.selectedItems.first {
                            navigationState.startRenaming(url: firstSelected.url)
                        }
                    }
                    .keyboardShortcut(.return, modifiers: [])

                    // F2 starts inline rename (Windows Explorer standard, CMD-03)
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if let firstSelected = navigationState.selectedItems.first {
                            navigationState.startRenaming(url: firstSelected.url)
                        }
                    }
                    .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF2FunctionKey)!)), modifiers: [])

                    // Cmd+Down to open selected item (Finder standard, CMD-03)
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if let firstSelected = navigationState.selectedItems.first {
                            handleActivate(firstSelected)
                        }
                    }
                    .keyboardShortcut(.downArrow, modifiers: .command)

                    // Cmd+O to open selected item
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        if let firstSelected = navigationState.selectedItems.first {
                            handleActivate(firstSelected)
                        }
                    }
                    .keyboardShortcut("o", modifiers: .command)

                    // Cmd+Up to navigate to enclosing folder (Finder standard, CMD-03)
                    Button("") {
                        guard !navigationState.isEditingPath && navigationState.renamingItemURL == nil else { return }
                        navigationState.goUp()
                    }
                    .keyboardShortcut(.upArrow, modifiers: .command)
                }
                .opacity(0)
                .allowsHitTesting(false)
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            if TerminalKeyboardOwnership.ownsFirstResponder(in: NSApp.keyWindow) {
                NSApp.keyWindow?.makeFirstResponder(NSApp.keyWindow?.contentView)
            }
        })
        .enableInjection()
    }

    private func setupFSEventsWatcher() {
        fseventsWatcher.watch(url: navigationState.currentURL) { [weak navigationState] in
            Task { @MainActor in
                await navigationState?.reloadCurrentDirectory()
            }
        }
    }

    // MARK: - Main Content Area
    @ViewBuilder
    private var contentArea: some View {
        if navigationState.isLoading && navigationState.items.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading directory...")
                    .foregroundColor(.secondary)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = navigationState.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
                Text("Unable to open directory")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                if navigationState.isPermissionError {
                    Text("Shark requires authorization to browse this folder.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    HStack(spacing: 8) {
                        Button("Grant Access...") {
                            Task { await navigationState.requestFolderAccess() }
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Privacy Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                        }
                    }
                }
                if navigationState.isPermissionError {
                    Button("Try Again") {
                        Task { await navigationState.reloadCurrentDirectory() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Try Again") {
                        Task { await navigationState.reloadCurrentDirectory() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if navigationState.filteredAndSortedItems.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text(navigationState.filterText.isEmpty ? "Folder is Empty" : "No Matching Items")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch navigationState.viewMode {
            case .details:
                DetailsTableView(
                    navigationState: navigationState,
                    onActivate: handleActivate,
                    contextMenu: contextMenu
                )
            case .grid:
                IconsGridView(
                    navigationState: navigationState,
                    onActivate: handleActivate,
                    contextMenu: contextMenu
                )
            case .compact:
                MillerColumnsView(
                    navigationState: navigationState,
                    onActivate: handleActivate,
                    contextMenu: contextMenu
                )
            case .gallery:
                galleryView
            }
        }
    }

    // MARK: - Gallery View
    private var galleryView: some View {
        VStack(spacing: 0) {
            let selectedItem = navigationState.filteredAndSortedItems.first { navigationState.selectedItemIDs.contains($0.id) }
                ?? navigationState.filteredAndSortedItems.first

            // Hero Preview Area
            if let item = selectedItem {
                VStack(spacing: 12) {
                    Spacer()
                    FileThumbnailView(item: item, size: 320)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(item.kindDescription) • \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
            }

            Divider()

            // Horizontal Filmstrip
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 12) {
                    ForEach(navigationState.filteredAndSortedItems) { item in
                        let isSelected = navigationState.selectedItemIDs.contains(item.id)
                        VStack(spacing: 4) {
                            FileThumbnailView(item: item, size: 48)
                                .frame(width: 48, height: 48)

                            Text(item.name)
                                .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                                .foregroundColor(isSelected ? .white : .primary)
                                .lineLimit(1)
                                .frame(width: 60)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isSelected ? Color.accentColor : Color.clear)
                                )
                        }
                        .contentShape(Rectangle())
                        .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
                        .onTapGesture {
                            navigationState.click(
                                item,
                                command: NSEvent.modifierFlags.contains(.command),
                                shift: NSEvent.modifierFlags.contains(.shift)
                            )
                        }
                        .onTapGesture(count: 2) {
                            handleActivate(item)
                        }
                        .fileItemAccessibility(item, isSelected: isSelected) { handleActivate(item) }
                        .fileDragSource(item: item, navigationState: navigationState)
                        .onRightClickSelect {
                            if !navigationState.selectedItemIDs.contains(item.url) {
                                navigationState.selectedItemIDs = [item.url]
                            }
                        }
                        .dropDestination(for: URL.self) { urls, _ in
                            guard item.isNavigableDirectory else { return false }
                            let modifiers = NSEvent.modifierFlags
                            Task { await navigationState.drop(urls, into: item.url, modifiers: modifiers) }
                            return true
                        }
                        .onMiddleClick {
                            if item.isNavigableDirectory {
                                workspace?.open(item.url, from: navigationState, newTab: true)
                            }
                        }
                        .contextMenu {
                            contextMenu(for: item)
                        }
                        .fileHoverPreview(item, isRenaming: navigationState.renamingItemURL == item.url)
                    }
                }
                .padding(10)
            }
            .frame(height: 90)
        }
    }

    // MARK: - Rich Status Bar
    private var statusBar: some View {
        HStack(spacing: 12) {
            let total = navigationState.items.count
            let filtered = navigationState.filteredAndSortedItems.count
            let selectedCount = navigationState.selectedItemIDs.count

            HStack(spacing: 6) {
                if !navigationState.filterText.isEmpty {
                    Text(L10n.format("%d of %d", filtered, total))
                } else {
                    Text(L10n.items(total))
                }

                if selectedCount > 0 {
                    let sizeStr = ByteCountFormatter.string(fromByteCount: navigationState.selectedTotalSize, countStyle: .file)
                    Text("• " + L10n.format("%@ (%@)", L10n.format("%d selected", selectedCount), sizeStr))
                        .foregroundColor(.primary)
                }

                if let diskSpaceSummary {
                    Text("• \(diskSpaceSummary)")
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)

            if let title = navigationState.activeOperationTitle {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text(title)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    if let cancel = navigationState.cancelActiveOperation {
                        Button(action: cancel) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.text("Stop"))
                        .accessibilityLabel(L10n.format("Stop: %@", title))
                    }
                }
            }

            Spacer()

            if navigationState.viewMode == .grid {
                HStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Slider(value: $navigationState.iconSize, in: 48...192, step: 8)
                        .frame(width: 100)

                    Image(systemName: "photo.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .liquidGlassBackground(material: .headerView)
        .overlay(Divider(), alignment: .top)
    }

    // MARK: - Actions
    private func handleActivate(_ item: FileItem) {
        if item.isNavigableDirectory {
            let isCmd = NSEvent.modifierFlags.contains(.command)
            if let workspace {
                workspace.open(item.url, from: navigationState, newTab: isCmd)
            } else {
                navigationState.navigateTo(item.url)
            }
        } else if UserDefaults.standard.bool(forKey: "openImagesInShark"), PhotoViewerWindowController.supports(url: item.url) {
            PhotoViewerWindowController.open(items: navigationState.filteredAndSortedItems, initialURL: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    @ViewBuilder
    private func contextMenu(for item: FileItem) -> some View {
        let targets = FileContextSelection.items(clicked: item, selected: navigationState.selectedItemIDs, ordered: navigationState.filteredAndSortedItems)
        let urls = targets.map(\.url)
        let isMultiple = targets.count > 1
        Button(isMultiple ? L10n.format("Open %d Items", targets.count) : L10n.text("Open"), systemImage: "arrow.up.forward.app") {
            openContextItems(targets)
        }
        if OpenWithService.canOpenWith(targets) {
            Menu(L10n.text("Open With"), systemImage: "arrow.up.forward.square") {
                let apps = OpenWithService.applications(for: targets)
                if apps.isEmpty {
                    Text(isMultiple ? L10n.text("No app opens all of these files") : L10n.text("No compatible apps"))
                }
                ForEach(apps, id: \.self) { app in
                    Button(app.deletingPathExtension().lastPathComponent) {
                        OpenWithService.open(urls, with: app) { navigationState.operationError = $0 }
                    }
                }
                Divider()
                Button(L10n.text("Other…"), systemImage: "ellipsis.circle") {
                    OpenWithService.chooseApplication(for: urls) { navigationState.operationError = $0 }
                }
            }
        }
        if !item.isDirectory {
            if targets.allSatisfy({ PhotoViewerWindowController.supports(url: $0.url) }) {
                Button(L10n.text("Open in Shark Photo Viewer"), systemImage: "photo.on.rectangle") {
                    PhotoViewerWindowController.open(items: navigationState.filteredAndSortedItems, initialURL: item.url)
                }
                if isMultiple {
                    Button(L10n.text("View Selected Photos"), systemImage: "photo.stack") {
                        PhotoViewerWindowController.open(items: targets, initialURL: item.url, selectedURLs: Set(urls))
                    }
                }
            }
            if !isMultiple { Button(L10n.text("Shark Preview"), systemImage: "macwindow") { previewItem = item } }
        }
        if !isMultiple && item.isNavigableDirectory {
            Button(L10n.text("Open in New Tab"), systemImage: "plus.rectangle.on.rectangle") { workspace?.newTab(url: item.url) }
            Button(L10n.text("Browse Subfolders…"), systemImage: "list.bullet.indent") {
                let builder = SubfolderMenuBuilder { url, inNewTab in
                    if inNewTab { workspace?.open(url, from: navigationState, newTab: true) }
                    else { navigationState.navigateTo(url) }
                }
                if let event = NSApp.currentEvent, let view = NSApp.keyWindow?.contentView {
                    NSMenu.popUpContextMenu(builder.buildMenu(for: item.url), with: event, for: view)
                }
            }
        }
        Button(L10n.text("Quick Look"), systemImage: "eye") { QuickLookCoordinator.shared.toggleQuickLook(for: urls) }
        Button(L10n.text("Share…"), systemImage: "square.and.arrow.up") { OpenWithService.share(urls) }
        Button(L10n.text("Show in Finder"), systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting(urls) }
        Divider()
        TerminalMenuItems(url: isMultiple ? navigationState.currentURL : item.url, workspace: workspace, source: navigationState)
        Divider()
        Button(L10n.text("Cut"), systemImage: "scissors") { FileClipboardService.shared.cut(urls) }
        Button(L10n.text("Copy"), systemImage: "doc.on.doc") { FileClipboardService.shared.copy(urls) }
        if !isMultiple && item.isNavigableDirectory && FileClipboardService.shared.hasItemsToPaste {
            Button(L10n.text("Paste into Folder"), systemImage: "doc.on.clipboard") {
                Task { await navigationState.paste(into: item.url) }
            }
        }
        Divider()
        Button(isMultiple ? L10n.text("Batch Rename…") : L10n.text("Rename"), systemImage: "pencil") {
            if isMultiple { contextRenameItems = targets; showingBatchRenameSheet = true }
            else { navigationState.startRenaming(url: item.url) }
        }
        Button(L10n.text("Duplicate"), systemImage: "plus.square.on.square") { performContextOperation(.duplicate, urls: urls) }
        Button(L10n.text("Compress"), systemImage: "archivebox") { performContextOperation(.compress, urls: urls) }
        Menu(L10n.text("Copy Path"), systemImage: "link") {
            Button(L10n.text("Full Path")) { copyContextText(urls.map(\.path).joined(separator: "\n")) }
            Button(L10n.text("Relative Path")) { copyContextText(targets.map(\.name).joined(separator: "\n")) }
            Button(L10n.text("POSIX Quoted Path")) { copyContextText(urls.map { $0.path.shellQuoted }.joined(separator: " ")) }
        }
        if !isMultiple && item.isDirectory {
            Button(L10n.text("Calculate Size"), systemImage: "chart.pie") { FolderSizeCalculator.shared.requestSize(for: item.url) }
        }
        Divider()
        Button(isMultiple ? L10n.format("Move %d Items to Trash", targets.count) : L10n.text("Move to Trash"), systemImage: "trash", role: .destructive) {
            performContextOperation(.trash, urls: urls)
        }
    }

    private func copyContextText(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func openContextItems(_ items: [FileItem]) {
        if items.count > 20 {
            let alert = NSAlert()
            alert.messageText = L10n.format("Open %d Items?", items.count)
            alert.informativeText = L10n.text("This may open many application windows.")
            alert.addButton(withTitle: L10n.text("Open"))
            alert.addButton(withTitle: L10n.text("Cancel"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        for item in items {
            if items.count > 1 && item.isNavigableDirectory { workspace?.newTab(url: item.url, select: false) }
            else { handleActivate(item) }
        }
    }

    private enum ContextOperation { case duplicate, compress, trash }
    private func performContextOperation(_ operation: ContextOperation, urls: [URL]) {
        guard !urls.isEmpty else { return }
        Task {
            do {
                switch operation {
                case .duplicate:
                    let created = try await FileOperationsService.shared.duplicate(items: urls)
                    FileUndoService.shared.record(.create(urls: created, name: L10n.text("Duplicate")))
                case .compress:
                    let archive = try await FileOperationsService.shared.compress(items: urls)
                    FileUndoService.shared.record(.create(urls: [archive], name: L10n.text("Compress")))
                case .trash:
                    let restored = try await FileOperationsService.shared.trash(items: urls)
                    FileUndoService.shared.record(.trash(restorations: restored))
                    navigationState.selectedItemIDs.subtract(urls)
                }
            } catch { navigationState.operationError = error.localizedDescription }
            await navigationState.reloadCurrentDirectory()
        }
    }

    @ViewBuilder
    private var directoryBackgroundContextMenu: some View {
        // Same actions, labels and icons as the item menu, applied to the current selection.
        let selected = navigationState.selectedItems
        let urls = selected.map(\.url)
        let count = selected.count

        if count > 0 {
            Button(count == 1 ? L10n.text("Open") : L10n.format("Open %d Items", count), systemImage: "arrow.up.forward.app") {
                openContextItems(selected)
            }
            Button(L10n.text("Quick Look"), systemImage: "eye") { QuickLookCoordinator.shared.toggleQuickLook(for: urls) }
            Button(L10n.text("Show in Finder"), systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting(urls) }
            Divider()
            Button(L10n.text("Cut"), systemImage: "scissors") { FileClipboardService.shared.cut(urls) }
            Button(L10n.text("Copy"), systemImage: "doc.on.doc") { FileClipboardService.shared.copy(urls) }
            Divider()
            Button(count == 1 ? L10n.text("Rename") : L10n.text("Batch Rename…"), systemImage: "pencil") {
                if count == 1, let only = selected.first { navigationState.startRenaming(url: only.url) }
                else { contextRenameItems = selected; showingBatchRenameSheet = true }
            }
            Button(L10n.text("Duplicate"), systemImage: "plus.square.on.square") { performContextOperation(.duplicate, urls: urls) }
            Button(L10n.text("Compress"), systemImage: "archivebox") { performContextOperation(.compress, urls: urls) }
            Divider()
            Button(count == 1 ? L10n.text("Move to Trash") : L10n.format("Move %d Items to Trash", count), systemImage: "trash", role: .destructive) {
                performContextOperation(.trash, urls: urls)
            }
            Divider()
        }

        Button(L10n.text("New Folder"), systemImage: "folder.badge.plus") { showingNewItemSheet = .folder }
        Button(L10n.text("New File"), systemImage: "doc.badge.plus") { showingNewItemSheet = .file }
        if FileClipboardService.shared.hasItemsToPaste {
            Button(L10n.text("Paste"), systemImage: "doc.on.clipboard") { Task { await navigationState.paste() } }
        }
        Divider()
        TerminalMenuItems(url: navigationState.currentURL, workspace: workspace, source: navigationState)
        Button(L10n.text("Reload"), systemImage: "arrow.clockwise") {
            Task { await navigationState.reloadCurrentDirectory() }
        }
        Button(navigationState.showHiddenFiles ? L10n.text("Hide Hidden Files") : L10n.text("Show Hidden Files"),
               systemImage: navigationState.showHiddenFiles ? "eye.slash" : "eye") {
            navigationState.showHiddenFiles.toggle()
        }
        Divider()
        Menu(L10n.text("Copy Path"), systemImage: "link") {
            Button(L10n.text("Full Path")) {
                copyContextText(count > 0 ? urls.map(\.path).joined(separator: "\n") : navigationState.currentURL.path)
            }
            Button(L10n.text("POSIX Quoted Path")) {
                copyContextText(count > 0 ? urls.map { $0.path.shellQuoted }.joined(separator: " ") : navigationState.currentURL.path.shellQuoted)
            }
        }
    }
}

extension String {

    /// Elides the middle so long names keep their start and ending (e.g. the extension) in compact menus.
    func middleTruncated(to limit: Int) -> String {
        guard limit > 1, count > limit else { return self }
        let head = limit / 2
        return prefix(head) + "…" + suffix(limit - 1 - head)
    }
}

extension View {
    /// Makes a custom file cell readable and openable with VoiceOver.
    func fileItemAccessibility(_ item: FileItem, isSelected: Bool, isRenaming: Bool = false, onOpen: @escaping () -> Void) -> some View {
        // While renaming, the text field inside must stay reachable.
        accessibilityElement(children: isRenaming ? .contain : .ignore)
            .accessibilityLabel(item.name)
            .accessibilityValue(item.isDirectory ? "Folder" : item.kindDescription)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction { onOpen() }
    }
}
