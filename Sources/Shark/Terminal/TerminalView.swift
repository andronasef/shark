import SwiftUI
import AppKit
import SwiftTerm

public struct TerminalView: NSViewRepresentable {
    @Bindable var session: PTYSession

    public init(session: PTYSession) {
        self.session = session
    }

    public func makeNSView(context: Context) -> LocalProcessTerminalView {
        let terminalView = LocalProcessTerminalView(frame: .zero)
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalView.nativeBackgroundColor = NSColor(white: 0.12, alpha: 1.0)
        terminalView.nativeForegroundColor = NSColor(white: 0.94, alpha: 1.0)

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        terminalView.startProcess(
            executable: shell,
            args: ["-l"],
            environment: nil,
            execName: nil,
            currentDirectory: session.currentWorkingDirectory.path
        )

        session.attach(terminalView: terminalView)
        return terminalView
    }

    public func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Writing observable state during a view update re-invalidates the view; attach only once.
        if session.terminalView !== nsView {
            session.attach(terminalView: nsView)
        }
    }
}
