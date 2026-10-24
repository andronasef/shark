import AppKit
import SwiftUI

struct TerminalMenuItems: View {
    let url: URL
    let workspace: WorkspaceState?
    let source: NavigationState

    var body: some View {
        Button(L10n.text("Open in Terminal")) {
            Task {
                do { try await TerminalOpener.shared.open(at: url) }
                catch { NSAlert(error: error).runModal() }
            }
        }
        if let workspace {
            Button(L10n.text("Open in Embedded Terminal")) {
                do { try workspace.openEmbeddedTerminal(at: url, from: source) }
                catch { NSAlert(error: error).runModal() }
            }
        }
    }
}
