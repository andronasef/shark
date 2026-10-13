import SwiftUI
import AppKit

@main
struct SharkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 500)
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
                    // Handled in ContentView
                }
                .keyboardShortcut(".", modifiers: [.command, .shift])
            }
        }
    }
}
