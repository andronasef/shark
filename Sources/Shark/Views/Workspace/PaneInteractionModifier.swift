import AppKit
import SwiftUI

/// Activates a pane before nested controls or native tables consume the event.
struct PaneInteractionModifier: ViewModifier {
    let isActive: Bool
    let activate: () -> Void

    func body(content: Content) -> some View {
        content.overlay(PaneInteractionRegion(isActive: isActive, activate: activate))
    }
}

private struct PaneInteractionRegion: NSViewRepresentable {
    let isActive: Bool
    let activate: () -> Void

    func makeNSView(context: Context) -> PaneInteractionNSView {
        let view = PaneInteractionNSView()
        view.isActive = isActive
        view.activate = activate
        return view
    }

    func updateNSView(_ view: PaneInteractionNSView, context: Context) {
        view.isActive = isActive
        view.activate = activate
    }

    static func dismantleNSView(_ view: PaneInteractionNSView, coordinator: ()) {
        view.stopMonitoring()
    }
}

private final class PaneInteractionNSView: NSView {
    var isActive = false
    var activate: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel]) { [weak self] event in
            guard let self,
                  event.window === self.window,
                  !self.isHiddenOrHasHiddenAncestor,
                  self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil)) else { return event }
            if !self.isActive {
                // Release a table/text field in the old pane; the original
                // mouse event can then focus the control in the new pane.
                self.window?.makeFirstResponder(nil)
                self.activate?()
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

extension View {
    func onPaneInteraction(isActive: Bool, activate: @escaping () -> Void) -> some View {
        modifier(PaneInteractionModifier(isActive: isActive, activate: activate))
    }
}
