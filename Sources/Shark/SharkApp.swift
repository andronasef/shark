import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct SharkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 850, minHeight: 550)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()

            CommandMenu("View") {
                Button("Toggle Split View") {
                    // Handled in ContentView via F3 / ⌥⌘S
                }
                .keyboardShortcut("s", modifiers: [.command, .option])

                Divider()

                Button("Show/Hide Hidden Files") {
                    // Handled in ContentView via ⇧⌘.
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}
