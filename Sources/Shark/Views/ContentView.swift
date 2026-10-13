import SwiftUI
import AppKit
import Inject

public struct ContentView: View {
    @ObserveInjection var inject

    @State private var workspaceState = WorkspaceState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isTerminalVisible = false
    @State private var isInspectorVisible = false
    @State private var terminalSession = PTYSession()

    @State private var showingNewItemSheet: NewItemType?
    @State private var showingBatchRenameSheet = false

    public init() {}

    private var activeState: NavigationState {
        workspaceState.activeNavigationState
    }

    private var inspectorTargetURL: URL {
        if let firstSelected = activeState.selectedItemIDs.first {
            return firstSelected
        }
        return activeState.currentURL
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PlacesSidebarView(navigationState: activeState)
                .navigationSplitViewColumnWidth(min: 170, ideal: 210, max: 280)
        } detail: {
            VStack(spacing: 0) {
                // Tab Bar matching Finder's sub-toolbar
                TabBarView(workspaceState: workspaceState)

                // Filter Bar (Cmd+I)
                if activeState.isFilterBarVisible {
                    filterBar
                }

                // Middle Area: Dual Pane + optional Right Inspector
                HStack(spacing: 0) {
                    DualPaneContainerView(tab: workspaceState.activeTab)
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
                if isTerminalVisible {
                    TerminalDrawerContainerView(
                        session: terminalSession,
                        isPresented: $isTerminalVisible
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: activeState.currentURL) { _, newURL in
            if isTerminalVisible {
                terminalSession.syncDirectory(to: newURL)
            }
        }
        .sheet(item: $showingNewItemSheet) { itemType in
            NewItemSheet(
                type: itemType,
                parentURL: activeState.currentURL,
                onCreated: {
                    Task { await activeState.reloadCurrentDirectory() }
                }
            )
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
        .toolbar {
            // MARK: - Navigation Group: Back / Forward & Current Title
            ToolbarItem(id: "nav-history", placement: .navigation) {
                VStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Button(action: { activeState.goBack() }) {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 22, height: 20)
                        }
                        .disabled(!activeState.canGoBack)
                        .buttonStyle(.plain)

                        Divider()
                            .frame(height: 14)

                        Button(action: { activeState.goForward() }) {
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 22, height: 20)
                        }
                        .disabled(!activeState.canGoForward)
                        .buttonStyle(.plain)
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

                    Text("Back/Forward")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .help("Navigation History (⌘[ / ⌘])")
            }

            ToolbarItem(id: "current-title", placement: .navigation) {
                HStack(spacing: 6) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: activeState.currentURL.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(activeState.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : activeState.currentURL.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .padding(.leading, 4)
            }

            // MARK: - Actions
            ToolbarItem(id: "path-menu", placement: .primaryAction) {
                Menu {
                    BreadcrumbMenuContent(navigationState: activeState)
                } label: {
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
                .menuStyle(.borderlessButton)
                .help("Show Path Hierarchy")
            }

            ToolbarItem(id: "view-mode", placement: .primaryAction) {
                VStack(spacing: 2) {
                    Picker("View", selection: Bindable(activeState).viewMode) {
                        Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                        Image(systemName: "list.bullet").tag(ViewMode.details)
                        Image(systemName: "rectangle.split.3x1").tag(ViewMode.compact)
                        Image(systemName: "macwindow").tag(ViewMode.gallery)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 116)

                    Text("View")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            ToolbarItem(id: "group-menu", placement: .primaryAction) {
                Menu {
                    Picker("Sort By", selection: Bindable(activeState).sortField) {
                        ForEach(SortField.allCases) { field in
                            Text(field.rawValue).tag(field)
                        }
                    }
                    Divider()
                    Button(activeState.sortAscending ? "Descending" : "Ascending") {
                        activeState.sortAscending.toggle()
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                            .font(.system(size: 13))
                            .frame(height: 18)
                        Text("Group")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 36)
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help("Group & Sort")
            }

            ToolbarItem(id: "share-button", placement: .primaryAction) {
                Button(action: {
                    shareCurrentSelection()
                }) {
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
            }

            ToolbarItem(id: "tags-button", placement: .primaryAction) {
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
            }

            ToolbarItem(id: "action-menu", placement: .primaryAction) {
                Menu {
                    Button("New Folder") { showingNewItemSheet = .folder }
                    Button("New File") { showingNewItemSheet = .file }
                    Divider()
                    Button("Get Info (⌘I)") { isInspectorVisible.toggle() }
                    Button("Duplicate (⌘D)") { duplicateSelected() }
                    Button("Rename...") {
                        if activeState.selectedItemIDs.count > 1 {
                            showingBatchRenameSheet = true
                        }
                    }
                    Divider()
                    Button("Move to Trash (⌘⌫)") { trashSelectedItems() }
                    Divider()
                    Button("Show Hidden Files (⇧⌘.)") { activeState.showHiddenFiles.toggle() }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 13))
                            .frame(height: 18)
                        Text("Action")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 36)
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help("Action Menu")
            }

            // MARK: - Dolphin Features: Split & Terminal
            ToolbarItem(id: "split-view", placement: .primaryAction) {
                Button(action: {
                    workspaceState.toggleSplit()
                }) {
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
            }

            ToolbarItem(id: "terminal-view", placement: .primaryAction) {
                Button(action: {
                    toggleTerminalDrawer()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: isTerminalVisible ? "terminal.fill" : "terminal")
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
                .help("Toggle Terminal")
            }

            // MARK: - Search Field
            ToolbarItem(id: "search-field", placement: .primaryAction) {
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
                Button("") { toggleTerminalDrawer() }.keyboardShortcut("t", modifiers: [.command, .shift])
                Button("") { isInspectorVisible.toggle() }.keyboardShortcut("i", modifiers: [.command, .option])
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
        isTerminalVisible.toggle()
        if isTerminalVisible {
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

private struct BreadcrumbMenuContent: View {
    @Bindable var navigationState: NavigationState

    var body: some View {
        let segments = getSegments()
        ForEach(segments, id: \.self) { url in
            Button(action: {
                navigationState.navigateTo(url)
            }) {
                HStack {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    Text(url.lastPathComponent.isEmpty ? "Macintosh HD" : url.lastPathComponent)
                }
            }
        }
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
