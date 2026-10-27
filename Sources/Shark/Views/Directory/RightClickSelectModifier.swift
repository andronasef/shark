import SwiftUI
import AppKit

public struct RightClickSelectModifier: ViewModifier {
    let onRightClick: () -> Void

    public func body(content: Content) -> some View {
        content
            .overlay(
                RightClickRepresentable(onRightClick: onRightClick)
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
        // Forward the right-click to the next responder so SwiftUI .contextMenu receives it
        nextResponder?.rightMouseDown(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Only claim hit-test when the mouse event is explicitly rightMouseDown
        if let currentEvent = NSApp.currentEvent, currentEvent.type == .rightMouseDown {
            if bounds.contains(point) {
                return self
            }
        }
        return nil
    }
}

public extension View {
    func onRightClickSelect(perform action: @escaping () -> Void) -> some View {
        modifier(RightClickSelectModifier(onRightClick: action))
    }
}

/// Runs a context-menu builder only when SwiftUI evaluates the menu, not when each cell is made.
/// Building every visible cell's menu (selection, Open With, photo support, labels) dominated scrolling.
struct DeferredMenu<Content: View>: View {
    let build: () -> Content
    var body: some View { build() }
}
