import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let session = SessionStore()
    lazy var workspace = session.restore() ?? WorkspaceState()

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        MiddleClick.install()
        session.startAutosave(workspace)

        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        session.saveNow(workspace)
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
