import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let workspace: WorkspaceState
    private var sessionStore: SessionStore?

    override init() {
        let store = SessionStore()
        if let restored = store.restore() {
            self.workspace = restored
        } else {
            self.workspace = WorkspaceState()
        }
        self.sessionStore = store
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start debounced autosave
        sessionStore?.startAutosave(workspace)
        SideButtonNavigation.install(workspace: workspace)
        // Install drag operation patcher (move by default, copy with + only when holding Alt)
        DragOperationPatcher.install()
        // Initialize Firebase Analytics & Crashlytics
        TelemetryService.shared.initialize()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush final snapshot immediately
        sessionStore?.saveNow(workspace)
    }
}

@main
struct SharkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(workspaceState: appDelegate.workspace)
                .frame(minWidth: 850, minHeight: 550)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            TabCommands(workspace: appDelegate.workspace)
            ExplorerCommands(workspace: appDelegate.workspace)
            HelpCommands()
        }

        Window("Shark Help", id: "help") {
            HelpView()
        }

        Settings {
            SettingsView()
        }
    }
}

struct HelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Shark Help") { openWindow(id: "help") }
                .keyboardShortcut("?", modifiers: .command)
        }
    }
}

struct ExplorerCommands: Commands {
    let workspace: WorkspaceState

    private var nav: NavigationState {
        workspace.activeNavigationState
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Tab") {
                workspace.newTab(placement: .end)
            }
            .keyboardShortcut("t")

            Button("New Window") {
                NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Folder") {
                nav.requestedNewItemType = .folder
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("New File") {
                nav.requestedNewItemType = .file
            }

            Divider()

            Button("Open Selected") {
                if let first = nav.selectedItems.first {
                    if first.isDirectory {
                        nav.navigateTo(first.url)
                    } else {
                        NSWorkspace.shared.open(first.url)
                    }
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            .disabled(nav.selectedItemIDs.isEmpty)

            Button("Move to Trash") {
                let urls = nav.selectedItems.map(\.url)
                guard !urls.isEmpty else { return }
                Task {
                    do {
                        try await FileOperationsService.shared.trash(items: urls)
                        await nav.reloadCurrentDirectory()
                    } catch {}
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .disabled(nav.selectedItemIDs.isEmpty)
        }

        CommandGroup(replacing: .undoRedo) {
            Button("Undo \(FileUndoService.shared.currentUndoDescription ?? "")") {
                Task { await nav.undo() }
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!FileUndoService.shared.canUndo)

            Button("Redo \(FileUndoService.shared.currentRedoDescription ?? "")") {
                Task { await nav.redo() }
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!FileUndoService.shared.canRedo)
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Cut") {
                nav.cutSelected()
            }
            .keyboardShortcut("x", modifiers: .command)
            .disabled(nav.selectedItemIDs.isEmpty)

            Button("Copy") {
                nav.copySelected()
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(nav.selectedItemIDs.isEmpty)

            Button("Paste") {
                Task { await nav.paste() }
            }
            .keyboardShortcut("v", modifiers: .command)
            .disabled(!FileClipboardService.shared.hasItemsToPaste)

            Button("Select All") {
                nav.selectedItemIDs = Set(nav.items.map(\.url))
            }
            .keyboardShortcut("a", modifiers: .command)

            Divider()

            Button("Rename") {
                if let first = nav.selectedItems.first {
                    nav.startRenaming(url: first.url)
                }
            }
            .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF2FunctionKey)!)), modifiers: [])
            .disabled(nav.selectedItemIDs.isEmpty)
        }

        CommandMenu("Go") {
            Button("Back") {
                nav.goBack()
            }
            .keyboardShortcut(.leftArrow, modifiers: .option)
            .disabled(!nav.canGoBack)

            Button("Forward") {
                nav.goForward()
            }
            .keyboardShortcut(.rightArrow, modifiers: .option)
            .disabled(!nav.canGoForward)

            Button("Enclosing Folder") {
                nav.goUp()
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            .disabled(!nav.canGoUp)

            Button("Focus Address Bar") {
                nav.isEditingPath = true
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Go to Folder...") {
                nav.isEditingPath = true
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Divider()

            let home = FileManager.default.homeDirectoryForCurrentUser
            Button("Home") {
                nav.navigateTo(home)
            }
            .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("Desktop") {
                let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Desktop")
                nav.navigateTo(url)
            }
            .keyboardShortcut("d", modifiers: [.command, .option])

            Button("Documents") {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Documents")
                nav.navigateTo(url)
            }
            .keyboardShortcut("o", modifiers: [.command, .option])

            Button("Downloads") {
                let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Downloads")
                nav.navigateTo(url)
            }
            .keyboardShortcut("l", modifiers: [.command, .option])

            Button("Applications") {
                nav.navigateTo(URL(fileURLWithPath: "/Applications"))
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Button("Computer") {
                nav.navigateTo(URL(fileURLWithPath: "/"))
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            if !RecentFoldersService.shared.recentFolders.isEmpty {
                Menu("Recent Folders") {
                    ForEach(Array(RecentFoldersService.shared.recentFolders.prefix(10)), id: \.self) { url in
                        Button(url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent) {
                            nav.navigateTo(url)
                        }
                    }
                }
            }

            if !RecentFoldersService.shared.frequentFolders.isEmpty {
                Menu("Frequent Folders") {
                    ForEach(Array(RecentFoldersService.shared.frequentFolders.prefix(10)), id: \.self) { url in
                        Button(url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent) {
                            nav.navigateTo(url)
                        }
                    }
                }
            }
        }

        CommandGroup(after: .sidebar) {
            Button("Command Palette...") {
                workspace.toggleCommandPalette()
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            Button("as Icons") {
                nav.viewMode = .grid
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("as List") {
                nav.viewMode = .details
            }
            .keyboardShortcut("2", modifiers: .command)

            Button("as Columns") {
                nav.viewMode = .compact
            }
            .keyboardShortcut("3", modifiers: .command)

            Button("as Gallery") {
                nav.viewMode = .gallery
            }
            .keyboardShortcut("4", modifiers: .command)

            Divider()

            Button(nav.isBottomPathBarVisible ? "Hide Path Bar" : "Show Path Bar") {
                nav.isBottomPathBarVisible.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])

            Button("Toggle Dual Split View") {
                workspace.toggleSplit()
            }
            .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF3FunctionKey)!)), modifiers: [])

            Button("Toggle Terminal Drawer") {
                workspace.isTerminalVisible.toggle()
            }
            .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!)), modifiers: [])

            Button(nav.showHiddenFiles ? "Hide Hidden Files" : "Show Hidden Files") {
                nav.showHiddenFiles.toggle()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])

            Divider()

            Button("Zoom In") {
                nav.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                nav.zoomOut()
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Actual Size") {
                nav.resetZoom()
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}

struct TabCommands: Commands {
    let workspace: WorkspaceState

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Close Tab") {
                workspace.closeTab(id: workspace.activeTabID)
            }
            .keyboardShortcut("w")

            Button("Close Window") {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        CommandMenu("Tab") {
            Button("New Tab") {
                workspace.newTab(placement: .end)
            }
            .keyboardShortcut("t")

            Button("Reopen Closed Tab") {
                workspace.reopenClosedTab()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .disabled(workspace.closedTabs.isEmpty)

            if workspace.closedTabs.isEmpty {
                Button("Recently Closed") {}
                    .disabled(true)
            } else {
                Menu("Recently Closed") {
                    ForEach(Array(workspace.closedTabs.enumerated()), id: \.offset) { idx, closed in
                        Button(closed.tab.primary.url.lastPathComponent.isEmpty ? "Macintosh HD" : closed.tab.primary.url.lastPathComponent) {
                            workspace.reopenClosedTab(at: idx)
                        }
                    }
                }
            }

            Divider()

            Button("Show Next Tab") {
                workspace.nextTab()
            }
            .keyboardShortcut(.tab, modifiers: [.control])

            Button("Show Previous Tab") {
                workspace.previousTab()
            }
            .keyboardShortcut(.tab, modifiers: [.control, .shift])

            Group {
                Button("Select Tab 1") { workspace.selectTab(number: 1) }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                Button("Select Tab 2") { workspace.selectTab(number: 2) }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                Button("Select Tab 3") { workspace.selectTab(number: 3) }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                Button("Select Tab 4") { workspace.selectTab(number: 4) }
                    .keyboardShortcut("4", modifiers: [.command, .option])
                Button("Select Tab 5") { workspace.selectTab(number: 5) }
                    .keyboardShortcut("5", modifiers: [.command, .option])
                Button("Select Tab 6") { workspace.selectTab(number: 6) }
                    .keyboardShortcut("6", modifiers: [.command, .option])
                Button("Select Tab 7") { workspace.selectTab(number: 7) }
                    .keyboardShortcut("7", modifiers: [.command, .option])
                Button("Select Tab 8") { workspace.selectTab(number: 8) }
                    .keyboardShortcut("8", modifiers: [.command, .option])
                Button("Select Last Tab") { workspace.selectTab(number: 9) }
                    .keyboardShortcut("9", modifiers: [.command, .option])
            }

            Divider()

            Button(workspace.activeTab.isPinned ? "Unpin Tab" : "Pin Tab") {
                workspace.togglePin(id: workspace.activeTabID)
            }

            Button("Duplicate Tab") {
                workspace.duplicateTab(id: workspace.activeTabID)
            }

            Button(workspace.activeTab.isLocked ? "Unlock Tab" : "Lock Tab") {
                workspace.toggleLock(id: workspace.activeTabID)
            }

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(workspace.activeNavigationState.currentURL.path, forType: .string)
            }

            Divider()

            Menu("Tab Groups") {
                Button("Save Tabs as Group...") {
                    let groupName = "Group \(TabGroupService.shared.groups.count + 1)"
                    _ = TabGroupService.shared.saveGroup(name: groupName, tabs: workspace.tabs)
                }

                if !TabGroupService.shared.groups.isEmpty {
                    Divider()
                    ForEach(TabGroupService.shared.groups) { group in
                        Button(group.name) {
                            TabGroupService.shared.restore(group: group, into: workspace, replace: false)
                        }
                    }
                }
            }
        }
    }
}
