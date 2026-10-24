import SwiftUI
import AppKit
import SwiftTerm
import Observation

@Observable
@MainActor
public final class TerminalKeyboardOwnership {
    public static let shared = TerminalKeyboardOwnership()
    private var focusedWindows: Set<Int> = []

    public func isFocused(in window: NSWindow?) -> Bool {
        guard let window else { return false }
        return focusedWindows.contains(window.windowNumber)
    }

    public func refresh(in window: NSWindow?) {
        guard let window else { return }
        let focused = Self.ownsFirstResponder(in: window)
        let wasFocused = focusedWindows.contains(window.windowNumber)
        guard focused != wasFocused else { return }
        if focused { focusedWindows.insert(window.windowNumber) }
        else { focusedWindows.remove(window.windowNumber) }
    }

    public func clear(in window: NSWindow?) {
        guard let window else { return }
        if focusedWindows.contains(window.windowNumber) { focusedWindows.remove(window.windowNumber) }
    }

    public static func ownsFirstResponder(in window: NSWindow?) -> Bool {
        var responder = window?.firstResponder as? NSView
        while let view = responder {
            if view is SwiftTerm.TerminalView { return true }
            responder = view.superview
        }
        return false
    }
}

/// Intercept native editing equivalents before SwiftUI's file menu shortcuts.
@MainActor
final class SharkTerminalView: LocalProcessTerminalView {
    weak var session: PTYSession?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self,
              event.modifierFlags.intersection([.command, .control, .option]) == .command else {
            return super.performKeyEquivalent(with: event)
        }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "+", "=": session?.adjustFontSize(by: 1)
        case "-": session?.adjustFontSize(by: -1)
        case "0": session?.resetFontSize()
        case "c": copy(self)
        case "v": if session?.isRunning == true { paste(self) }
        case "a": selectAll(self)
        case "k": session?.clear()
        default: return super.performKeyEquivalent(with: event)
        }
        return true
    }

    override func send(source: SwiftTerm.TerminalView, data: ArraySlice<UInt8>) {
        guard session?.isRunning == true else { return }
        super.send(source: source, data: data)
    }
}

public struct TerminalView: NSViewRepresentable {
    @Bindable var session: PTYSession
    public init(session: PTYSession) { self.session = session }

    public func makeNSView(context: Context) -> NSView {
        let host = TerminalHostView()
        mount(in: host)
        return host
    }

    public func updateNSView(_ nsView: NSView, context: Context) { mount(in: nsView) }

    private func mount(in host: NSView) {
        let terminal = session.makeTerminalView()
        if terminal.superview !== host {
            host.subviews.forEach { $0.removeFromSuperview() }
            terminal.removeFromSuperview()
            terminal.translatesAutoresizingMaskIntoConstraints = false
            host.addSubview(terminal)
            NSLayoutConstraint.activate([
                terminal.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                terminal.trailingAnchor.constraint(equalTo: host.trailingAnchor),
                terminal.topAnchor.constraint(equalTo: host.topAnchor),
                terminal.bottomAnchor.constraint(equalTo: host.bottomAnchor)
            ])
            DispatchQueue.main.async { [weak session] in session?.focus() }
        }
        (host as? TerminalHostView)?.session = session
    }

    public static func dismantleNSView(_ nsView: NSView, coordinator: ()) {
        // Detach, never terminate. The window's session retains shell and scrollback.
        nsView.subviews.forEach { $0.removeFromSuperview() }
    }
}

@MainActor
private final class TerminalHostView: NSView {
    weak var session: PTYSession?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, let session else { return }
        session.attachWindow(window)
        DispatchQueue.main.async { [weak session] in session?.focus() }
    }
}
