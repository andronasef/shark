import SwiftUI

public struct ContentView: View {
    @State private var navigationState = NavigationState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PlacesSidebarView(navigationState: navigationState)
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 280)
        } detail: {
            VStack(spacing: 0) {
                // Filter Bar (Cmd+I)
                if navigationState.isFilterBarVisible {
                    HStack(spacing: 8) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.secondary)
                        TextField("Filter items (e.g. *.swift or filename)...", text: $navigationState.filterText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                        if !navigationState.filterText.isEmpty {
                            Button(action: { navigationState.filterText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Button(action: {
                            navigationState.isFilterBarVisible = false
                            navigationState.filterText = ""
                        }) {
                            Text("Done")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor))
                    Divider()
                }

                // Directory Contents View
                DirectoryView(navigationState: navigationState)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                // Back Button (Cmd+[)
                Button(action: { navigationState.goBack() }) {
                    Image(systemName: "chevron.backward")
                }
                .disabled(!navigationState.canGoBack)
                .help("Back (⌘[)")
                .keyboardShortcut("[", modifiers: .command)

                // Forward Button (Cmd+])
                Button(action: { navigationState.goForward() }) {
                    Image(systemName: "chevron.forward")
                }
                .disabled(!navigationState.canGoForward)
                .help("Forward (⌘])")
                .keyboardShortcut("]", modifiers: .command)

                // Up Button (Cmd+Up)
                Button(action: { navigationState.goUp() }) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!navigationState.canGoUp)
                .help("Enclosing Folder (⌘↑)")
                .keyboardShortcut(.upArrow, modifiers: .command)
            }

            ToolbarItem(placement: .principal) {
                BreadcrumbBarView(navigationState: navigationState)
                    .frame(minWidth: 260, idealWidth: 420)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                // Filter bar toggle (Cmd+I)
                Button(action: {
                    navigationState.isFilterBarVisible.toggle()
                }) {
                    Image(systemName: navigationState.isFilterBarVisible ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
                .help("Filter (⌘I)")
                .keyboardShortcut("i", modifiers: .command)

                // View Mode Picker
                Picker("View Mode", selection: $navigationState.viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Image(systemName: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                // Show Hidden Files Toggle (Cmd+Shift+.)
                Button(action: {
                    navigationState.showHiddenFiles.toggle()
                }) {
                    Image(systemName: navigationState.showHiddenFiles ? "eye.fill" : "eye.slash")
                }
                .help("Toggle Hidden Files (⇧⌘.)")
                .keyboardShortcut(".", modifiers: [.command, .shift])

                // Reload button (Cmd+R)
                Button(action: {
                    Task { await navigationState.reloadCurrentDirectory() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload (⌘R)")
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        // Direct Path Edit keyboard shortcut (Cmd+L)
        .background {
            Button("") {
                navigationState.pathInputText = navigationState.currentURL.path
                navigationState.isEditingPath.toggle()
            }
            .keyboardShortcut("l", modifiers: .command)
            .opacity(0)
        }
    }
}
