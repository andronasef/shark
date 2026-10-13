import SwiftUI
import AppKit

public struct ContentView: View {
    @State private var workspaceState = WorkspaceState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isTerminalVisible = false
    @State private var isInspectorVisible = false
    @State private var terminalSession = PTYSession()

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
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 280)
        } detail: {
            VStack(spacing: 0) {
                // Tab Bar
                TabBarView(workspaceState: workspaceState)

                // Filter Bar (Cmd+I)
                if activeState.isFilterBarVisible {
                    filterBar
                }

                // Middle Area: Dual Pane + optional Right Inspector
                HStack(spacing: 0) {
                    // Dual Pane or Single Pane Workspace Container
                    DualPaneContainerView(tab: workspaceState.activeTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Information Inspector Panel (F11)
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
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                // Back Button (Cmd+[)
                Button(action: { activeState.goBack() }) {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!activeState.canGoBack)
                .help("Back (⌘[)")
                .keyboardShortcut("[", modifiers: .command)

                // Forward Button (Cmd+])
                Button(action: { activeState.goForward() }) {
                    Image(systemName: "chevron.forward")
                }
                .disabled(!activeState.canGoForward)
                .help("Forward (⌘])")
                .keyboardShortcut("]", modifiers: .command)

                // Up Button (Cmd+Up)
                Button(action: { activeState.goUp() }) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!activeState.canGoUp)
                .help("Enclosing Folder (⌘↑)")
                .keyboardShortcut(.upArrow, modifiers: .command)
            }

            ToolbarItem(placement: .principal) {
                BreadcrumbBarView(navigationState: activeState)
                    .frame(minWidth: 260, idealWidth: 420)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                // Split View Toggle (F3 / Cmd+Option+S)
                Button(action: {
                    workspaceState.toggleSplit()
                }) {
                    Image(systemName: workspaceState.activeTab.isSplit ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                }
                .help("Toggle Split View (F3 or ⌥⌘S)")
                .keyboardShortcut("s", modifiers: [.command, .option])

                // Terminal Drawer Toggle (F4 / Cmd+Option+T)
                Button(action: {
                    toggleTerminalDrawer()
                }) {
                    Image(systemName: isTerminalVisible ? "terminal.fill" : "terminal")
                }
                .help("Toggle Terminal Drawer (F4 or ⌥⌘T)")
                .keyboardShortcut("t", modifiers: [.command, .option])

                // Inspector Toggle (F11 / Cmd+Option+I)
                Button(action: {
                    isInspectorVisible.toggle()
                }) {
                    Image(systemName: isInspectorVisible ? "info.circle.fill" : "info.circle")
                }
                .help("Toggle Information Inspector (F11 or ⌥⌘I)")
                .keyboardShortcut("i", modifiers: [.command, .option])

                // Filter bar toggle (Cmd+I)
                Button(action: {
                    activeState.isFilterBarVisible.toggle()
                }) {
                    Image(systemName: activeState.isFilterBarVisible ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .help("Filter (⌘I)")
                .keyboardShortcut("i", modifiers: .command)

                // View Mode Picker
                Picker("View Mode", selection: Bindable(activeState).viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                // Show Hidden Files Toggle (Cmd+Shift+.)
                Button(action: {
                    activeState.showHiddenFiles.toggle()
                }) {
                    Image(systemName: activeState.showHiddenFiles ? "eye.fill" : "eye.slash")
                }
                .help("Toggle Hidden Files (⇧⌘.)")
                .keyboardShortcut(".", modifiers: [.command, .shift])

                // Reload button (Cmd+R)
                Button(action: {
                    Task { await activeState.reloadCurrentDirectory() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload (⌘R)")
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        // Background Keyboard Shortcuts
        .background {
            Group {
                // Quick Look (Space)
                Button("") {
                    triggerQuickLook()
                }
                .keyboardShortcut(.space, modifiers: [])

                // View Mode Shortcuts (Cmd+1, Cmd+2, Cmd+3)
                Button("") { activeState.viewMode = .details }
                    .keyboardShortcut("1", modifiers: .command)

                Button("") { activeState.viewMode = .grid }
                    .keyboardShortcut("2", modifiers: .command)

                Button("") { activeState.viewMode = .compact }
                    .keyboardShortcut("3", modifiers: .command)

                // Direct Path Edit (Cmd+L)
                Button("") {
                    activeState.pathInputText = activeState.currentURL.path
                    activeState.isEditingPath.toggle()
                }
                .keyboardShortcut("l", modifiers: .command)

                // Switch Active Split Pane (Tab)
                Button("") {
                    workspaceState.toggleActivePane()
                }
                .keyboardShortcut(.tab, modifiers: [])

                // New Tab (Cmd+T)
                Button("") {
                    workspaceState.newTab()
                }
                .keyboardShortcut("t", modifiers: .command)

                // Close Tab (Cmd+W)
                Button("") {
                    workspaceState.closeTab(id: workspaceState.activeTabID)
                }
                .keyboardShortcut("w", modifiers: .command)

                // Next Tab (Cmd+Shift+])
                Button("") {
                    workspaceState.nextTab()
                }
                .keyboardShortcut("]", modifiers: [.command, .shift])

                // Previous Tab (Cmd+Shift+[)
                Button("") {
                    workspaceState.previousTab()
                }
                .keyboardShortcut("[", modifiers: [.command, .shift])
            }
            .opacity(0)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.secondary)
            TextField("Filter items (e.g. *.swift or filename)...", text: Bindable(activeState).filterText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
            if !activeState.filterText.isEmpty {
                Button(action: { activeState.filterText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button(action: {
                activeState.isFilterBarVisible = false
                activeState.filterText = ""
            }) {
                Text("Done")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(Divider(), alignment: .bottom)
    }

    private func toggleTerminalDrawer() {
        isTerminalVisible.toggle()
        if isTerminalVisible {
            terminalSession.syncDirectory(to: activeState.currentURL)
        }
    }

    private func triggerQuickLook() {
        let urls = Array(activeState.selectedItemIDs)
        if !urls.isEmpty {
            QuickLookCoordinator.shared.toggleQuickLook(for: urls)
        }
    }
}
