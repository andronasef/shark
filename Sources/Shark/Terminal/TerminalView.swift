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

enum TerminalKeyRouting {
    /// Whether a key-equivalent candidate belongs to the focused shell rather than the menu bar:
    /// anything without ⌘ that uses ⌃ or ⌥ or is a function/navigation key, except the drawer
    /// toggles F4 and ⌃` (so the terminal can still be hidden from the keyboard).
    static func shellOwns(modifiers: NSEvent.ModifierFlags, characters: String?) -> Bool {
        let mods = modifiers.intersection([.command, .control, .option])
        guard !mods.contains(.command), let scalar = characters?.unicodeScalars.first else { return false }
        if scalar.value == UInt32(NSF4FunctionKey) && mods.isEmpty { return false }
        if characters == "`" && mods == .control { return false }
        let isFunctionKey = (0xF700...0xF8FF).contains(scalar.value)
        return !mods.isEmpty || isFunctionKey
    }
}

/// Intercept native editing equivalents before SwiftUI's file menu shortcuts.
@MainActor
final class SharkTerminalView: LocalProcessTerminalView {
    weak var session: PTYSession?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self else { return super.performKeyEquivalent(with: event) }
        // Menu shortcuts without ⌘ (F2 rename, F3 split, ⌃Tab, ⌥←) would otherwise fire inside
        // htop, mc or vim. Hand them to the shell; only the drawer toggles stay with the app.
        if TerminalKeyRouting.shellOwns(modifiers: event.modifierFlags, characters: event.charactersIgnoringModifiers) {
            keyDown(with: event)
            return true
        }
        guard event.modifierFlags.intersection([.command, .control, .option]) == .command else {
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
