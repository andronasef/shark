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

    static func dismantleNSView(_ nsView: CommandScrollZoomNSView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

private class CommandScrollZoomNSView: NSView {
    var onZoom: ((CGFloat) -> Void)?

    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }

        // Scroll views can retain the wheel-event target for a gesture, so an
        // overlay's hitTest/scrollWheel is not a reliable interception point.
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self else { return event }
            return self.handleScroll(event)
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handleScroll(_ event: NSEvent) -> NSEvent? {
        guard event.window === window,
              !isHiddenOrHasHiddenAncestor,
              event.modifierFlags.contains(.command),
              visibleRect.contains(convert(event.locationInWindow, from: nil)),
              abs(event.scrollingDeltaY) > 0.05,
              let onZoom else { return event }

        onZoom(event.scrollingDeltaY)
        return nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Keep selection, context menus, and ordinary scrolling on the content.
        nil
    }
}

public extension View {
    func onCommandScrollZoom(perform action: @escaping (CGFloat) -> Void) -> some View {
        modifier(CommandScrollZoomModifier(onZoom: action))
    }
}
