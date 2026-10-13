import SwiftUI
import AppKit

public struct TerminalView: NSViewRepresentable {
    @Bindable var session: PTYSession

    public init(session: PTYSession) {
        self.session = session
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = TerminalNSView(session: session)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        context.coordinator.textView = textView

        session.onOutput = { _ in
            Task { @MainActor in
                context.coordinator.updateText()
            }
        }

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? TerminalNSView {
            textView.session = session
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    @MainActor
    public final class Coordinator {
        var session: PTYSession
        weak var textView: TerminalNSView?

        init(session: PTYSession) {
            self.session = session
        }

        func updateText() {
            guard let textView else { return }
            textView.string = session.outputText
            textView.scrollToEndOfDocument(nil)
        }
    }
}

final class TerminalNSView: NSTextView {
    var session: PTYSession?

    init(session: PTYSession) {
        self.session = session
        super.init(frame: .zero)
        configureTerminalAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTerminalAppearance() {
        self.backgroundColor = NSColor(white: 0.1, alpha: 1.0)
        self.textColor = NSColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
        self.insertionPointColor = NSColor.white
        self.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        self.isEditable = false
        self.isSelectable = true
        self.allowsUndo = false
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        guard let session else {
            super.keyDown(with: event)
            return
        }

        // Special keys handling (arrow keys, backspace, enter, tab)
        if let special = event.specialKey {
            switch special {
            case .upArrow:
                session.sendInput("\u{1b}[A")
                return
            case .downArrow:
                session.sendInput("\u{1b}[B")
                return
            case .rightArrow:
                session.sendInput("\u{1b}[C")
                return
            case .leftArrow:
                session.sendInput("\u{1b}[D")
                return
            case .delete:
                session.sendInput("\u{7f}")
                return
            default:
                break
            }
        }

        // Ctrl+C, Ctrl+D, Ctrl+L, etc.
        if event.modifierFlags.contains(.control), let characters = event.charactersIgnoringModifiers {
            if let first = characters.unicodeScalars.first {
                let asciiValue = first.value
                if asciiValue >= 97 && asciiValue <= 122 { // 'a'...'z'
                    let ctrlCode = UInt8(asciiValue - 96)
                    let data = Data([ctrlCode])
                    if let ctrlStr = String(data: data, encoding: .ascii) {
                        session.sendInput(ctrlStr)
                        return
                    }
                }
            }
        }

        if let characters = event.characters {
            // Translate Return to \r
            let translated = characters.replacingOccurrences(of: "\n", with: "\r")
            session.sendInput(translated)
        }
    }
}
