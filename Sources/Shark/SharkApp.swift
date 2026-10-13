import SwiftUI

@main
struct SharkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, minHeight: 450)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    // Handled in Phase 2
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("New Folder") {
                    // Handled in Phase 6
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}
