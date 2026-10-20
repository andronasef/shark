import SwiftUI
import AppKit

public struct RightClickSelectModifier: ViewModifier {
    let onRightClick: () -> Void

    public func body(content: Content) -> some View {
        content
            .overlay(
                RightClickRepresentable(onRightClick: onRightClick)
                    .allowsHitTesting(true)
            )
    }
}

private struct RightClickRepresentable: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> RightClickNSView {
        let view = RightClickNSView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: RightClickNSView, context: Context) {
        nsView.onRightClick = onRightClick
    }
}

private class RightClickNSView: NSView {
    var onRightClick: (() -> Void)?

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
        super.rightMouseDown(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only intercept right clicks so left clicks, double clicks, and drag gestures pass through unimpeded
        if let currentEvent = NSApp.currentEvent, currentEvent.type == .rightMouseDown {
            return self
        }
        return nil
    }
}

public extension View {
    func onRightClickSelect(perform action: @escaping () -> Void) -> some View {
        modifier(RightClickSelectModifier(onRightClick: action))
    }
}
