import AppKit

/// Preserve the framework delegate and its optional callbacks.
@MainActor
final class TerminalWindowCloseGuard: NSObject, NSWindowDelegate {
    weak var window: NSWindow?
    private weak var session: PTYSession?
    private var focusObserver: NSObjectProtocol?
    // Objective-C forwarding overrides are nonisolated; access remains on the main thread.
    nonisolated(unsafe) private weak var original: (any NSWindowDelegate)?

    init(window: NSWindow, session: PTYSession) {
        self.window = window
        self.session = session
        original = window.delegate
        super.init()
        window.delegate = self
        focusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didUpdateNotification,
            object: window, queue: .main) { [weak window] _ in
                MainActor.assumeIsolated { TerminalKeyboardOwnership.shared.refresh(in: window) }
            }
    }

    override func responds(to selector: Selector!) -> Bool {
        if super.responds(to: selector) { return true }
        guard Thread.isMainThread else { return false }
        return original?.responds(to: selector) ?? false
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        if Thread.isMainThread, original?.responds(to: selector) == true { return original }
        return super.forwardingTarget(for: selector)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard original?.windowShouldClose?(sender) ?? true else { return false }
        guard session?.isRunning == true else { return true }
        let alert = NSAlert()
        alert.messageText = L10n.text("Terminate this terminal session?")
        alert.informativeText = L10n.text("Closing this window terminates its shell and any running commands. Hide the terminal drawer to keep them running.")
        alert.addButton(withTitle: L10n.text("Cancel"))
        alert.addButton(withTitle: L10n.text("Terminate and Close"))
        return alert.runModal() == .alertSecondButtonReturn
    }

    func windowWillClose(_ notification: Notification) {
        session?.terminate()
        if let focusObserver { NotificationCenter.default.removeObserver(focusObserver) }
        focusObserver = nil
        TerminalKeyboardOwnership.shared.clear(in: window)
        original?.windowWillClose?(notification)
        if window?.delegate === self { window?.delegate = original }
    }
}
