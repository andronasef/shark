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
        // Install global NSEvent monitor for middle-click tab operations
        MiddleClick.install()
        // Install drag operation patcher (move by default, copy with + only when holding Alt)
        DragOperationPatcher.install()
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
        }
    }
}

struct ExplorerCommands: Commands {
    let workspace: WorkspaceState

    private var nav: NavigationState {
        workspace.activeNavigationState
    }

    var body: some Commands {
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

            Button("Up (Enclosing Folder)") {
                nav.goUp()
            }
            .keyboardShortcut(.upArrow, modifiers: .option)
            .disabled(!nav.canGoUp)

            Button("Focus Address Bar (Alt+D)") {
                nav.isEditingPath = true
            }
            .keyboardShortcut("d", modifiers: .option)

            Divider()

            Button("Go to Folder...") {
                nav.isEditingPath = true
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])

            Button("Focus Address Bar (Cmd+L)") {
                nav.isEditingPath = true
            }
            .keyboardShortcut("l", modifiers: .command)

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
            Button(nav.isBottomPathBarVisible ? "Hide Path Bar" : "Show Path Bar") {
                nav.isBottomPathBarVisible.toggle()
            }
            .keyboardShortcut("p", modifiers: [.command, .option])

            Divider()

            Button("Zoom In") {
                nav.zoomIn()
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom In (Equals)") {
                nav.zoomIn()
            }
            .keyboardShortcut("=", modifiers: .command)

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
        CommandGroup(replacing: .newItem) {}

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
        }

        CommandGroup(after: .toolbar) {
            Button("Toggle Split View") {
                workspace.toggleSplit()
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Button("Show/Hide Hidden Files") {
                workspace.activeNavigationState.showHiddenFiles.toggle()
            }
            .keyboardShortcut(".", modifiers: [.command, .shift])

            Button("Toggle Terminal") {
                workspace.isTerminalVisible.toggle()
            }
            .keyboardShortcut(KeyEquivalent(Character(UnicodeScalar(NSF4FunctionKey)!)), modifiers: [])
        }
    }
}
