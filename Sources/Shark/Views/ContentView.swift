import SwiftUI
import AppKit
import Inject

public struct ContentView: View {
    @ObserveInjection var inject

    @Bindable var workspaceState: WorkspaceState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isInspectorVisible = false
    @State private var terminalSession = PTYSession()

    @State private var showingNewItemSheet: NewItemType?
    @State private var showingBatchRenameSheet = false

    @State private var isShowingPathPopover = false
    @State private var isShowingGroupPopover = false
    @State private var isShowingActionPopover = false

    public init(workspaceState: WorkspaceState = WorkspaceState()) {
        self.workspaceState = workspaceState
    }

    private var activeState: NavigationState {
        workspaceState.activeNavigationState
    }

    private var inspectorTargetURL: URL {
        if let firstSelected = activeState.selectedItemIDs.first {
            return firstSelected
        }
        return activeState.currentURL
    }

    private var terminalVisibleBinding: Binding<Bool> {
        Binding(
            get: { workspaceState.isTerminalVisible },
            set: { workspaceState.isTerminalVisible = $0 }
        )
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PlacesSidebarView(navigationState: activeState)
                .navigationSplitViewColumnWidth(min: 170, ideal: 210, max: 280)
        } detail: {
            VStack(spacing: 0) {
                // Pro Tab Strip (QTTabBar / Finder look)
                TabStripView(workspace: workspaceState)

                // Filter Bar (Cmd+I)
                if activeState.isFilterBarVisible {
                    filterBar
                }

                // Middle Area: Dual Pane + optional Right Inspector
                HStack(spacing: 0) {
                    DualPaneContainerView(tab: workspaceState.activeTab)
                        .id(workspaceState.activeTabID)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if isInspectorVisible {
                        Divider()
                        InspectorPanelView(
                            targetURL: inspectorTargetURL,
                            isPresented: $isInspectorVisible
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Embedded Terminal Drawer (F4)
                if workspaceState.isTerminalVisible {
                    TerminalDrawerContainerView(
                        session: terminalSession,
                        isPresented: terminalVisibleBinding
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                // MARK: - Left: Back / Forward & Current Title
                ToolbarItem(id: "nav-history", placement: .navigation) {
                    HStack(spacing: 8) {
                        VStack(spacing: 2) {
                            HStack(spacing: 0) {
                                // Windows Explorer style Back (Alt+Left)
                                Button(action: { activeState.goBack() }) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 24, height: 22)
                                }
                                .disabled(!activeState.canGoBack)
                                .buttonStyle(.plain)
                                .help("Back (Alt + ←)")
                                .accessibilityLabel("Navigate Back")

                                Divider()
                                    .frame(height: 14)

                                // Windows Explorer style Forward (Alt+Right)
                                Button(action: { activeState.goForward() }) {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 24, height: 22)
                                }
                                .disabled(!activeState.canGoForward)
                                .buttonStyle(.plain)
                                .help("Forward (Alt + →)")
                                .accessibilityLabel("Navigate Forward")

                                Divider()
                                    .frame(height: 14)

                                // Windows Explorer style Up to Parent (Alt+Up)
                                Button(action: { activeState.goUp() }) {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 24, height: 22)
                                }
                                .disabled(!activeState.canGoUp)
                                .buttonStyle(.plain)
                                .help("Up (Alt + ↑)")
                            }
                            .padding(.horizontal, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                            )

                            Text("Navigation")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 6) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: activeState.currentURL.path))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                            Text(activeState.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : activeState.currentURL.lastPathComponent)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        }
                    }
                    .help("Navigation History (⌘[ / ⌘])")
                }

                // MARK: - Center Flexible Space (Pushes Actions to Trailing)
                ToolbarItem(placement: .principal) {
                    Spacer()
                }

                // MARK: - Right: Action Tools Grouped Trailing (Finder Layout)
                ToolbarItemGroup(placement: .primaryAction) {
                    // Path Button + Popover
                    Button(action: { isShowingPathPopover.toggle() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "list.bullet.below.rectangle")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Path")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Show Path Hierarchy")
                    .accessibilityLabel("Path Hierarchy")
                    .popover(isPresented: $isShowingPathPopover, arrowEdge: .bottom) {
                        BreadcrumbPopoverView(
                            navigationState: activeState,
                            workspaceState: workspaceState,
                            isPresented: $isShowingPathPopover
                        )
                    }

                    // View Segmented Picker
                    VStack(spacing: 2) {
                        Picker("View", selection: Bindable(activeState).viewMode) {
                            Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                            Image(systemName: "list.bullet").tag(ViewMode.details)
                            Image(systemName: "rectangle.split.3x1").tag(ViewMode.compact)
                            Image(systemName: "macwindow").tag(ViewMode.gallery)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityLabel("View Mode")
                        .frame(width: 176)

                        Text("View")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)

                    // Group Button + Popover
                    Button(action: { isShowingGroupPopover.toggle() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Group")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 34)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Group & Sort")
                    .accessibilityLabel("Group and Sort")
                    .popover(isPresented: $isShowingGroupPopover, arrowEdge: .bottom) {
                        GroupPopoverView(navigationState: activeState, isPresented: $isShowingGroupPopover)
                    }

                    // Share
                    Button(action: { shareCurrentSelection() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Share")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 32)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Share Selection")
                    .accessibilityLabel("Share Selection")

                    // Add Tags
                    Button(action: {}) {
                        VStack(spacing: 2) {
                            Image(systemName: "tag")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Add Tags")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Add Tags")
                    .accessibilityLabel("Add Tags")

                    // Action
                    Button(action: { isShowingActionPopover.toggle() }) {
                        VStack(spacing: 2) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Action")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 34)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Action Menu")
                    .accessibilityLabel("Action Menu")
                    .popover(isPresented: $isShowingActionPopover, arrowEdge: .bottom) {
                        ActionPopoverView(
                            activeState: activeState,
                            isPresented: $isShowingActionPopover,
                            onNewFolder: { showingNewItemSheet = .folder },
                            onNewFile: { showingNewItemSheet = .file },
                            onGetInfo: { isInspectorVisible.toggle() },
                            onDuplicate: { duplicateSelected() },
                            onRename: {
                                if activeState.selectedItemIDs.count > 1 {
                                    showingBatchRenameSheet = true
                                }
                            },
                            onTrash: { trashSelectedItems() }
                        )
                    }

                    // Split & Terminal
                    Button(action: { workspaceState.toggleSplit() }) {
                        VStack(spacing: 2) {
                            Image(systemName: workspaceState.activeTab.isSplit ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Split")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 30)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Split View")
                    .accessibilityLabel("Toggle Split View")

                    Button(action: { toggleTerminalDrawer() }) {
                        VStack(spacing: 2) {
                            Image(systemName: workspaceState.isTerminalVisible ? "terminal.fill" : "terminal")
                                .font(.system(size: 13))
                                .frame(height: 18)
                            Text("Terminal")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Terminal (F4)")
                    .accessibilityLabel("Toggle Terminal")

                    // Search Field
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))

                            TextField("Search", text: Bindable(activeState).filterText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .frame(width: 90)

                            if !activeState.filterText.isEmpty {
                                Button(action: { activeState.filterText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )

                        Text("Search")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .environment(workspaceState)
        .onChange(of: activeState.currentURL) { _, newURL in
            if workspaceState.isTerminalVisible {
                terminalSession.syncDirectory(to: newURL)
            }
        }
        .onChange(of: workspaceState.isTerminalVisible) { _, visible in
            if visible {
                terminalSession.syncDirectory(to: activeState.currentURL)
            }
        }
        .sheet(item: Binding(
            get: { showingNewItemSheet ?? activeState.requestedNewItemType },
            set: {
                showingNewItemSheet = $0
                activeState.requestedNewItemType = $0
            }
        )) { itemType in
            NewItemSheet(
                type: itemType,
                parentURL: activeState.currentURL,
                onCreated: {
                    Task { await activeState.reloadCurrentDirectory() }
                }
            )
        }
        .overlay {
            if workspaceState.isCommandPalettePresented {
                CommandPaletteView(workspace: workspaceState)
            }
        }
        .sheet(isPresented: $showingBatchRenameSheet) {
            let selectedItems = activeState.items.filter { activeState.selectedItemIDs.contains($0.id) }
            BatchRenameSheet(
                items: selectedItems,
                onRenameComplete: {
                    Task { await activeState.reloadCurrentDirectory() }
                }
            )
        }
        .background {
            Group {
                Button("") { triggerQuickLook() }.keyboardShortcut(.space, modifiers: [])
                Button("") { trashSelectedItems() }.keyboardShortcut(.delete, modifiers: .command)
                Button("") {
                    if activeState.selectedItemIDs.count > 1 { showingBatchRenameSheet = true }
                }.keyboardShortcut("r", modifiers: [.command, .shift])
                Button("") { activeState.viewMode = .grid }.keyboardShortcut("1", modifiers: .command)
                Button("") { activeState.viewMode = .details }.keyboardShortcut("2", modifiers: .command)
                Button("") { activeState.viewMode = .compact }.keyboardShortcut("3", modifiers: .command)
                Button("") { activeState.viewMode = .gallery }.keyboardShortcut("4", modifiers: .command)
                Button("") { workspaceState.toggleSplit() }.keyboardShortcut("s", modifiers: [.command, .shift])
                Button("") { workspaceState.previousTab() }.keyboardShortcut("[", modifiers: [.command, .shift])
                Button("") { workspaceState.nextTab() }.keyboardShortcut("]", modifiers: [.command, .shift])
                Button("") { isInspectorVisible.toggle() }.keyboardShortcut("i", modifiers: [.command, .option])
                Button("") { workspaceState.toggleCommandPalette() }.keyboardShortcut("k", modifiers: .command)
                Button("") { workspaceState.toggleCommandPalette() }.keyboardShortcut("p", modifiers: [.command, .shift])
                Button("") { workspaceState.toggleSplit() }.keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF3FunctionKey)!)), modifiers: [])
                Button("") { toggleTerminalDrawer() }.keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!)), modifiers: [])
                Button("") { isInspectorVisible.toggle() }.keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF11FunctionKey)!)), modifiers: [])
                Button("") { activeState.requestedNewItemType = .folder }.keyboardShortcut("n", modifiers: [.command, .shift])
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
        .enableInjection()
    }

    private var filterBar: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundColor(.secondary)
            TextField("Filter filenames in current folder...", text: Bindable(activeState).filterText)
                .textFieldStyle(.plain)
            if !activeState.filterText.isEmpty {
                Button(action: { activeState.filterText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button("Done") {
                activeState.isFilterBarVisible = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .overlay(Divider(), alignment: .bottom)
    }

    private func toggleTerminalDrawer() {
        workspaceState.isTerminalVisible.toggle()
        if workspaceState.isTerminalVisible {
            terminalSession.syncDirectory(to: activeState.currentURL)
        }
    }

    private func triggerQuickLook() {
        guard let firstID = activeState.selectedItemIDs.first else { return }
        QuickLookCoordinator.shared.toggleQuickLook(for: [firstID])
    }

    private func trashSelectedItems() {
        let urls = Array(activeState.selectedItemIDs)
        guard !urls.isEmpty else { return }
        Task {
            try? await FileOperationsService.shared.trash(items: urls)
            await activeState.reloadCurrentDirectory()
        }
    }

    private func duplicateSelected() {
        let urls = Array(activeState.selectedItemIDs)
        guard !urls.isEmpty else { return }
        Task {
            try? await FileOperationsService.shared.duplicate(items: urls)
            await activeState.reloadCurrentDirectory()
        }
    }

    private func shareCurrentSelection() {
        let urls = Array(activeState.selectedItemIDs)
        guard !urls.isEmpty else { return }
        let picker = NSSharingServicePicker(items: urls)
        if let window = NSApp.keyWindow {
            picker.show(relativeTo: .zero, of: window.contentView ?? NSView(), preferredEdge: .minY)
        }
    }
}

// MARK: - Breadcrumb Popover
private struct BreadcrumbPopoverView: View {
    @Bindable var navigationState: NavigationState
    let workspaceState: WorkspaceState
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Path Hierarchy")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()

            let segments = getSegments()
            ForEach(segments, id: \.self) { url in
                let isCurrent = (url.standardizedFileURL.path == navigationState.currentURL.standardizedFileURL.path)
                Button(action: {
                    let isCmd = NSEvent.modifierFlags.contains(.command)
                    workspaceState.open(url, from: navigationState, newTab: isCmd)
                    isPresented = false
                }) {
                    HStack(spacing: 8) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                            .resizable()
                            .frame(width: 16, height: 16)
                        Text(url.lastPathComponent.isEmpty ? "Macintosh HD" : url.lastPathComponent)
                            .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
                            .foregroundColor(isCurrent ? .accentColor : .primary)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onMiddleClick {
                    workspaceState.open(url, from: navigationState, newTab: true)
                    isPresented = false
                }
            }
        }
        .padding(.bottom, 6)
        .frame(minWidth: 220)
    }

    private func getSegments() -> [URL] {
        var res: [URL] = []
        var cur = navigationState.currentURL.standardizedFileURL
        while true {
            res.insert(cur, at: 0)
            if cur.path == "/" { break }
            let parent = cur.deletingLastPathComponent()
            if parent.path == cur.path { break }
            cur = parent
        }
        return res
    }
}

// MARK: - Group Popover
private struct GroupPopoverView: View {
    @Bindable var navigationState: NavigationState
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sort By")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)

            Divider()

            ForEach(SortField.allCases) { field in
                let isSelected = (navigationState.sortField == field)
                Button(action: {
                    navigationState.sortField = field
                    isPresented = false
                }) {
                    HStack {
                        Text(field.rawValue)
                            .font(.system(size: 12))
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider()

            Button(action: {
                navigationState.sortAscending.toggle()
                isPresented = false
            }) {
                HStack {
                    Text(navigationState.sortAscending ? "Descending" : "Ascending")
                        .font(.system(size: 12))
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 6)
        .frame(minWidth: 160)
    }
}

// MARK: - Action Popover
private struct ActionPopoverView: View {
    let activeState: NavigationState
    @Binding var isPresented: Bool
    let onNewFolder: () -> Void
    let onNewFile: () -> Void
    let onGetInfo: () -> Void
    let onDuplicate: () -> Void
    let onRename: () -> Void
    let onTrash: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            popoverItem("New Folder", icon: "folder.badge.plus") {
                isPresented = false
                onNewFolder()
            }
            popoverItem("New File", icon: "doc.badge.plus") {
                isPresented = false
                onNewFile()
            }
            Divider()
            popoverItem("Get Info (⌘I)", icon: "info.circle") {
                isPresented = false
                onGetInfo()
            }
            popoverItem("Duplicate (⌘D)", icon: "plus.square.on.square") {
                isPresented = false
                onDuplicate()
            }
            popoverItem("Rename...", icon: "pencil") {
                isPresented = false
                onRename()
            }
            Divider()
            popoverItem("Move to Trash (⌘⌫)", icon: "trash", isDestructive: true) {
                isPresented = false
                onTrash()
            }
            Divider()
            popoverItem("Show Hidden Files (⇧⌘.)", icon: activeState.showHiddenFiles ? "eye.slash" : "eye") {
                activeState.showHiddenFiles.toggle()
                isPresented = false
            }
        }
        .padding(6)
        .frame(minWidth: 190)
    }

    private func popoverItem(_ title: String, icon: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isDestructive ? .red : .primary)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isDestructive ? .red : .primary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
