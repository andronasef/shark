import SwiftUI
import AppKit
import Inject

public struct ContentView: View {
    @ObserveInjection var inject

    @Bindable var workspaceState: WorkspaceState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    /// Width of the detail column, which is the width the toolbar items share.
    @State private var detailWidth: CGFloat = 1000
    @State private var isInspectorVisible = false
    @State private var terminalSession = PTYSession()
    @State private var lastHandledTerminalRequestID: UUID?

    @State private var showingNewItemSheet: NewItemType?
    @State private var showingBatchRenameSheet = false

    @State private var isShowingPathPopover = false
    @State private var isShowingGroupPopover = false
    @State private var isShowingActionPopover = false

    public init(workspaceState: WorkspaceState = WorkspaceState()) {
        self.workspaceState = workspaceState
    }

    /// Toolbar items never stretch on their own, so the Location capsule is sized from the detail
    /// width minus what the other items use (Navigation plus Path through Search, with gaps).
    /// Includes the native spacing between toolbar groups; retune if controls change.
    private static let otherToolbarItemsWidth: CGFloat = 768

    /// With the sidebar hidden the detail column spans the whole window, so the traffic lights and
    /// sidebar button also sit in the toolbar row. Without this the capsule is too wide and macOS
    /// moves Back/Forward/Up into the overflow menu.
    /// Native leading controls occupy 116 pt in the collapsed layout.
    private static let collapsedSidebarInset: CGFloat = 116

    private var locationWidth: CGFloat {
        let inset = columnVisibility == .detailOnly ? Self.collapsedSidebarInset : 0
        return max(160, detailWidth - Self.otherToolbarItemsWidth - inset)
    }

    @ToolbarContentBuilder
    private var finderToolbar: some ToolbarContent {
        ToolbarItem(id: "nav-history", placement: .navigation) {
            HStack(alignment: .top, spacing: 14) {
                FinderToolbarCaption("Navigation") {
                    HStack(spacing: 0) {
                        Button { activeState.goBack() } label: {
                            Image(systemName: "chevron.left").frame(width: 27, height: 28)
                                .contentShape(Rectangle())
                        }
                        .disabled(!activeState.canGoBack)
                        .help("Back (⌘[)")
                        .accessibilityLabel("Navigate Back")
                        Divider().frame(height: 14)
                        Button { activeState.goForward() } label: {
                            Image(systemName: "chevron.right").frame(width: 27, height: 28)
                                .contentShape(Rectangle())
                        }
                        .disabled(!activeState.canGoForward)
                        .help("Forward (⌘])")
                        .accessibilityLabel("Navigate Forward")
                        Divider().frame(height: 14)
                        Button { activeState.goUp() } label: {
                            Image(systemName: "chevron.up").frame(width: 27, height: 28)
                                .contentShape(Rectangle())
                        }
                        .disabled(!activeState.canGoUp)
                        .help("Enclosing Folder (⌘↑)")
                        .accessibilityLabel("Navigate Up")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .buttonStyle(.plain)
                    .finderGlass()
                    .contextMenu {
                        Button("Enclosing Folder") { activeState.goUp() }
                            .disabled(!activeState.canGoUp)
                    }
                }
            }
        }
        .finderChromeItem()

        // Left-aligned beside Navigation, taking all the width the other toolbar items leave.
        ToolbarItem(id: "location", placement: .navigation) {
            Group {
                if activeState.isBottomPathBarVisible || activeState.isEditingPath {
                    FinderToolbarCaption("Location") {
                        BottomPathBarView(navigationState: activeState, workspace: workspaceState, inToolbar: true)
                    }
                } else {
                    Text(activeState.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : activeState.currentURL.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .frame(height: 28)
                }
            }
            .frame(width: locationWidth)
        }
        .finderChromeItem()

        // Keeps the right-hand controls at the trailing edge if the location ends early.
        ToolbarItem(placement: .principal) { Spacer() }
            .finderChromeItem()

        ToolbarItem(id: "path", placement: .primaryAction) {
            FinderToolbarCaption("Path") {
                Button { isShowingPathPopover.toggle() } label: {
                    FinderToolbarSymbol(symbol: "list.bullet", disclosure: true)
                }
                .buttonStyle(.plain)
                .finderGlass()
                .accessibilityLabel("Path Hierarchy")
                .help("Show Path Hierarchy")
                .popover(isPresented: $isShowingPathPopover, arrowEdge: .bottom) {
                    BreadcrumbPopoverView(navigationState: activeState, workspaceState: workspaceState, isPresented: $isShowingPathPopover)
                }
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "view-mode", placement: .primaryAction) {
            FinderToolbarCaption("View") {
                HStack(spacing: 0) {
                    viewModeButton(.grid, symbol: "square.grid.2x2", label: "Icons")
                    viewModeButton(.details, symbol: "list.bullet", label: "List")
                    Divider().frame(height: 16)
                    viewModeButton(.compact, symbol: "rectangle.split.3x1", label: "Columns")
                    Divider().frame(height: 16)
                    viewModeButton(.gallery, symbol: "rectangle.bottomthird.inset.filled", label: "Gallery")
                }
                .padding(.horizontal, 3)
                .frame(height: 28)
                .finderGlass()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("View Mode")
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "group-sort", placement: .primaryAction) {
            FinderToolbarCaption("Group") {
                Button { isShowingGroupPopover.toggle() } label: {
                    FinderToolbarSymbol(symbol: "square.grid.3x3", disclosure: true)
                }
                .buttonStyle(.plain)
                .finderGlass()
                .accessibilityLabel("Group and Sort")
                .help("Group & Sort")
                .popover(isPresented: $isShowingGroupPopover, arrowEdge: .bottom) {
                    GroupPopoverView(navigationState: activeState, isPresented: $isShowingGroupPopover)
                }
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "share", placement: .primaryAction) {
            FinderToolbarCaption("Share") {
                Button { shareCurrentSelection() } label: {
                    FinderToolbarSymbol(symbol: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .finderGlass()
                .disabled(activeState.selectedItemIDs.isEmpty)
                .help("Share Selection")
                .accessibilityLabel("Share Selection")
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "tags", placement: .primaryAction) {
            FinderToolbarCaption("Edit Tags") {
                Button {} label: { FinderToolbarSymbol(symbol: "tag") }
                    .buttonStyle(.plain)
                    .finderGlass()
                    .disabled(true)
                    .help("Tag editing is not yet available")
                    .accessibilityLabel("Edit Tags")
            }
        }
        .finderChromeItem()


        utilityToolbar
    }

    @ToolbarContentBuilder
    private var utilityToolbar: some ToolbarContent {
        ToolbarItem(id: "split", placement: .primaryAction) {
            FinderToolbarCaption("Split") {
                Button { workspaceState.toggleSplit() } label: {
                    FinderToolbarSymbol(symbol: workspaceState.activeTab.isSplit ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                }
                .buttonStyle(.plain)
                .finderGlass(isSelected: workspaceState.activeTab.isSplit)
                .help("Toggle Split View (F3)")
                .accessibilityLabel("Toggle Split View")
                .accessibilityValue(workspaceState.activeTab.isSplit ? "On" : "Off")
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "terminal", placement: .primaryAction) {
            FinderToolbarCaption("Terminal") {
                Button { toggleTerminalDrawer() } label: {
                    FinderToolbarSymbol(symbol: workspaceState.isTerminalVisible ? "terminal.fill" : "terminal")
                }
                .buttonStyle(.plain)
                .finderGlass(isSelected: workspaceState.isTerminalVisible)
                .help("Toggle Terminal (F4)")
                .accessibilityLabel("Toggle Terminal")
                .accessibilityValue(workspaceState.isTerminalVisible ? "On" : "Off")
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "actions", placement: .primaryAction) {
            FinderToolbarCaption("Action") {
                Button { isShowingActionPopover.toggle() } label: {
                    FinderToolbarSymbol(symbol: "ellipsis")
                }
                .buttonStyle(.plain)
                .finderGlass()
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
                            if activeState.selectedItemIDs.count > 1 { showingBatchRenameSheet = true }
                        },
                        onTrash: { trashSelectedItems() },
                        onToggleSplit: { workspaceState.toggleSplit() },
                        onToggleTerminal: { toggleTerminalDrawer() }
                    )
                }
            }
        }
        .finderChromeItem()

        ToolbarItem(id: "search", placement: .primaryAction) {
            FinderToolbarCaption("Search") {
                FinderSearchField(text: Bindable(activeState).filterText)
            }
        }
        .finderChromeItem()
    }

    private func viewModeButton(_ mode: ViewMode, symbol: String, label: String) -> some View {
        Button { activeState.viewMode = mode } label: {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .frame(width: 27, height: 24)
                .background {
                    if activeState.viewMode == mode {
                        Capsule().fill(Color.primary.opacity(0.15))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label + " View")
        .accessibilityAddTraits(activeState.viewMode == mode ? .isSelected : [])
    }

    private var activeState: NavigationState {
        workspaceState.activeNavigationState
    }

    private var inspectorTargetURL: URL {
        if let anchor = activeState.selectionAnchorID, activeState.selectedItemIDs.contains(anchor) {
            return anchor
        }
        if let firstSelected = activeState.selectedItems.first {
            return firstSelected.url
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
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.size.width, initial: true) { _, width in detailWidth = width }
            })
            .toolbar { finderToolbar }
        }
        .environment(workspaceState)
        .onChange(of: activeState.currentURL) { _, newURL in
            if workspaceState.isTerminalVisible {
                // A new terminal request may activate another pane in this same
                // update. Let its target win over the pane's current directory.
                if let request = workspaceState.embeddedTerminalRequest,
                   request.id != lastHandledTerminalRequestID { return }
                workspaceState.embeddedTerminalRequest = nil
                terminalSession.syncDirectory(to: newURL)
            }
        }
        .onChange(of: workspaceState.isTerminalVisible) { _, visible in
            TelemetryService.shared.logTerminalToggled(isVisible: visible)
            if visible {
                if workspaceState.embeddedTerminalRequest == nil {
                    terminalSession.syncDirectory(to: activeState.currentURL)
                }
            } else {
                workspaceState.embeddedTerminalRequest = nil
            }
        }
        .onChange(of: activeState.viewMode) { _, newMode in
            TelemetryService.shared.logViewModeChanged(mode: newMode.rawValue)
        }
        .onChange(of: workspaceState.embeddedTerminalRequest) { _, request in
            if let request {
                terminalSession.syncDirectory(to: request.directory)
                lastHandledTerminalRequestID = request.id
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

    private func toggleTerminalDrawer() {
        workspaceState.isTerminalVisible.toggle()
    }

    private func triggerQuickLook() {
        let urls = activeState.selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        QuickLookCoordinator.shared.toggleQuickLook(for: urls)
    }

    private func trashSelectedItems() {
        Task { await activeState.trashSelected() }
    }

    private func duplicateSelected() {
        Task { await activeState.duplicateSelected() }
    }

    private func shareCurrentSelection() {
        let urls = activeState.selectedItems.map(\.url)
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
    let onToggleSplit: () -> Void
    let onToggleTerminal: () -> Void

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
            popoverItem("Enclosing Folder", icon: "arrow.up") {
                isPresented = false
                activeState.goUp()
            }
            popoverItem("Toggle Split View (F3)", icon: "rectangle.split.2x1", action: {
                isPresented = false
                onToggleSplit()
            })
            popoverItem("Toggle Terminal (F4)", icon: "terminal", action: {
                isPresented = false
                onToggleTerminal()
            })
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
