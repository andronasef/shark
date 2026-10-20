import SwiftUI
import AppKit

public struct CommandScrollZoomModifier: ViewModifier {
    let onZoom: (CGFloat) -> Void

    public init(onZoom: @escaping (CGFloat) -> Void) {
        self.onZoom = onZoom
    }

    public func body(content: Content) -> some View {
        content
            .overlay(
                CommandScrollZoomRepresentable(onZoom: onZoom)
                    .allowsHitTesting(true)
            )
    }
}

private struct CommandScrollZoomRepresentable: NSViewRepresentable {
    let onZoom: (CGFloat) -> Void

    func makeNSView(context: Context) -> CommandScrollZoomNSView {
        let view = CommandScrollZoomNSView()
        view.onZoom = onZoom
        return view
    }

    func updateNSView(_ nsView: CommandScrollZoomNSView, context: Context) {
        nsView.onZoom = onZoom
    }
}

private class CommandScrollZoomNSView: NSView {
    var onZoom: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            let delta = event.scrollingDeltaY
            if abs(delta) > 0.05 {
                onZoom?(delta)
                return
            }
        }
        // Forward ordinary scroll wheel event up the responder chain to the NSScrollView
        nextResponder?.scrollWheel(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Intercept when Command is pressed during scroll, otherwise allow all mouse clicks & gestures to pass through
        if let currentEvent = NSApp.currentEvent {
            if currentEvent.type == .scrollWheel && currentEvent.modifierFlags.contains(.command) {
                if bounds.contains(point) {
                    return self
                }
            }
        }
        return nil
    }
}

public extension View {
    func onCommandScrollZoom(perform action: @escaping (CGFloat) -> Void) -> some View {
        modifier(CommandScrollZoomModifier(onZoom: action))
    }
}
