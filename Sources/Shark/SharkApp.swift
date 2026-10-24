import SwiftUI
import AppKit
import SwiftTerm

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let workspace: WorkspaceState
    var showMainWindow: (() -> Void)?
    @Published var folderOpenError: String?
    private var sessionStore: SessionStore?

    override init() {
        AppLocalization.configureAtStartup()
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
        UpdateChecker.checkAutomatically()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush final snapshot immediately
        sessionStore?.saveNow(workspace)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Open events provide sandbox access. Persist that grant for restored tabs when possible.
        if SecurityScopedBookmarkManager.shared.isSandboxed {
            for url in urls where url.isFileURL {
                _ = try? SecurityScopedBookmarkManager.shared.saveBookmark(for: url)
            }
        }
        let rejected = workspace.openExternalFolders(urls)
        if !rejected.isEmpty {
            folderOpenError = "Shark opens existing folders, not individual files or app packages. Check that the folder exists and that Shark has permission to access it."
        }
        showMainWindow?()
        application.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow?()
        return true
    }
}

@main
struct SharkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var onboarding = OnboardingState()
    @AppStorage(AppLocalization.preferenceKey) private var languagePreference = AppLanguage.system.rawValue

    var body: some Scene {
        // One window: the menu commands and the session drive a single WorkspaceState, so a second
        // window would only mirror the first one's tabs. Use tabs (⌘T) for more locations.
        Window("Shark", id: "main") {
            MainWindowView(appDelegate: appDelegate, onboarding: onboarding)
                .environment(\.locale, AppLocalization.locale)
                .environment(\.layoutDirection, AppLocalization.layoutDirection)
                .frame(minWidth: 850, minHeight: 550)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            TabCommands(workspace: appDelegate.workspace)
            ExplorerCommands(workspace: appDelegate.workspace)
            HelpCommands(onboarding: onboarding)
        }

        Window("Shark Help", id: "help") {
            HelpView()
                .environment(\.locale, AppLocalization.locale)
                .environment(\.layoutDirection, AppLocalization.layoutDirection)
        }

        Settings {
            SettingsView()
                .environment(\.locale, AppLocalization.locale)
                .environment(\.layoutDirection, AppLocalization.layoutDirection)
        }
    }
}

private struct MainWindowView: View {
    @ObservedObject var appDelegate: AppDelegate
    @Bindable var onboarding: OnboardingState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ContentView(workspaceState: appDelegate.workspace)
            .onAppear {
                appDelegate.showMainWindow = { openWindow(id: "main") }
            }
            .task {
                await Task.yield()
                onboarding.presentIfNeeded()
            }
            .sheet(isPresented: $onboarding.isPresented) { OnboardingView() }
            .alert("Couldn’t Open Folder", isPresented: Binding(
                get: { appDelegate.folderOpenError != nil },
                set: { if !$0 { appDelegate.folderOpenError = nil } }
            )) {
                Button("OK") { appDelegate.folderOpenError = nil }
            } message: {
                Text(appDelegate.folderOpenError ?? "")
            }
    }
}

struct HelpCommands: Commands {
    let onboarding: OnboardingState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openURL) private var openURL

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Shark") {
                AppLinks.showAboutPanel()
            }
        }

        CommandGroup(after: .appInfo) {
            Button("Check for Updates…") { UpdateChecker.checkNow() }
        }

        CommandGroup(replacing: .help) {
            Button("Welcome to Shark") {
                openWindow(id: "main")
                onboarding.show()
            }

            Button("Shark Help") { openWindow(id: "help") }
                .keyboardShortcut("?", modifiers: .command)

            Button("All Features") {
                openURL(AppLinks.features)
            }

            Divider()

            Button("Shark Website") {
                openURL(AppLinks.website)
            }

            Button("Source Code on GitHub") {
                openURL(AppLinks.repository)
            }

            Button("Send Feedback…") {
                openURL(AppLinks.feedback)
            }

            Divider()

            Button("About Andrew Nasef") {
                openURL(AppLinks.author)
            }
        }
    }
}

/// Sends an editing action to the focused text field or terminal instead of the file list.
/// The Edit menu's ⌘X/⌘C/⌘V/⌘A/⌘Z/⌘⌫ are file commands here, and menu key equivalents reach the
/// menu before the field editor, so without this they would move or trash files while typing.
@MainActor
func forwardToTextEditor(_ action: Selector) -> Bool {
    guard let responder = (NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }))?.firstResponder,
          responder is NSText || responder is SwiftTerm.TerminalView else { return false }
    // Even an unsupported editing action belongs to this responder. Falling through would
    // turn (for example) an unavailable terminal Undo into an unrelated file undo.
    _ = NSApp.sendAction(action, to: nil, from: nil)
    return true
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
                if forwardToTextEditor(#selector(NSResponder.deleteToBeginningOfLine(_:))) { return }
                Task { await nav.trashSelected() }
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }

        CommandGroup(after: .toolbar) {
            Button(L10n.text("Customize Toolbar…")) {
                (NSApp.keyWindow ?? NSApp.mainWindow)?.toolbar?.runCustomizationPalette(nil)
            }
        }

        CommandGroup(replacing: .undoRedo) {
            // Not disabled when the file history is empty: text fields still need ⌘Z.
            Button(FileUndoService.shared.currentUndoDescription.map { L10n.format("Undo: %@", $0) } ?? L10n.text("Undo")) {
                if forwardToTextEditor(Selector(("undo:"))) { return }
                Task { await nav.undo() }
            }
            .keyboardShortcut("z", modifiers: .command)

            Button(FileUndoService.shared.currentRedoDescription.map { L10n.format("Redo: %@", $0) } ?? L10n.text("Redo")) {
                if forwardToTextEditor(Selector(("redo:"))) { return }
                Task { await nav.redo() }
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .pasteboard) {
            // Never disabled: with a text field focused these edit its text instead.
            Button("Cut") {
                if forwardToTextEditor(#selector(NSText.cut(_:))) { return }
                nav.cutSelected()
            }
            .keyboardShortcut("x", modifiers: .command)

            Button("Copy") {
                if forwardToTextEditor(#selector(NSText.copy(_:))) { return }
                nav.copySelected()
            }
            .keyboardShortcut("c", modifiers: .command)

            Button("Paste") {
                if forwardToTextEditor(#selector(NSText.paste(_:))) { return }
                Task { await nav.paste() }
            }
            .keyboardShortcut("v", modifiers: .command)

            Button("Select All") {
                if forwardToTextEditor(#selector(NSText.selectAll(_:))) { return }
                nav.selectAll()
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
                if forwardToTextEditor(#selector(NSResponder.moveWordLeft(_:))) { return }
                nav.goBack()
            }
            .keyboardShortcut(.leftArrow, modifiers: .option)
            .disabled(!nav.canGoBack)

            Button("Forward") {
                if forwardToTextEditor(#selector(NSResponder.moveWordRight(_:))) { return }
                nav.goForward()
            }
            .keyboardShortcut(.rightArrow, modifiers: .option)
            .disabled(!nav.canGoForward)

            Button("Enclosing Folder") {
                if forwardToTextEditor(#selector(NSResponder.moveToBeginningOfDocument(_:))) { return }
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
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Documents") {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Documents")
                nav.navigateTo(url)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

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
                if workspace.activeTab.isLocked { NSSound.beep(); return }
                workspace.closeTab(id: workspace.activeTabID)
            }
            .keyboardShortcut("w")

            Button("Close Window") {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        CommandMenu("Tab") {
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
