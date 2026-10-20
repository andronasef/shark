import SwiftUI
import AppKit

public struct MiddleClickModifier: ViewModifier {
    let action: () -> Void

    public func body(content: Content) -> some View {
        content.overlay(MiddleClickRegion(action: action))
    }
}

private struct MiddleClickRegion: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> MiddleClickNSView {
        let view = MiddleClickNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: MiddleClickNSView, context: Context) {
        nsView.action = action
    }

    static func dismantleNSView(_ nsView: MiddleClickNSView, coordinator: ()) {
        nsView.stopMonitoring()
    }
}

private final class MiddleClickNSView: NSView {
    var action: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [weak self] event in
            guard let self,
                  event.buttonNumber == 2,
                  event.window === self.window,
                  !self.isHiddenOrHasHiddenAncestor,
                  self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil)),
                  let action = self.action else { return event }
            // Use the actual click position, including after a tab closes under
            // a stationary pointer. No global hover target can go stale.
            action()
            return nil
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Leave selection, context menus, and drag gestures with the content.
        nil
    }
}

public extension View {
    func onMiddleClick(_ action: @escaping () -> Void) -> some View {
        modifier(MiddleClickModifier(action: action))
    }
}
