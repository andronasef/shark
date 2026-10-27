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

@MainActor
private final class MiddleClickRegistry {
    static let shared = MiddleClickRegistry()
    private let views = NSHashTable<MiddleClickNSView>.weakObjects()
    private var monitor: Any?

    func register(_ view: MiddleClickNSView) {
        views.add(view)
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .otherMouseUp) { [weak self] event in
            guard event.buttonNumber == 2, let self else { return event }
            for view in self.views.allObjects {
                guard view.window === event.window, !view.isHiddenOrHasHiddenAncestor,
                      view.bounds.intersection(view.visibleRect).contains(view.convert(event.locationInWindow, from: nil)) else { continue }
                if let scroll = view.enclosingScrollView,
                   !scroll.documentVisibleRect.contains(view.convert(view.convert(event.locationInWindow, from: nil), to: scroll.documentView)) { continue }
                guard let action = view.action else { continue }
                action()
                return nil
            }
            return event
        }
    }

    func unregister(_ view: MiddleClickNSView) {
        views.remove(view)
        if views.allObjects.isEmpty, let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

private final class MiddleClickNSView: NSView {
    var action: (() -> Void)?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        if window != nil { MiddleClickRegistry.shared.register(self) }
    }
    func stopMonitoring() { MiddleClickRegistry.shared.unregister(self) }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

public extension View {
    func onMiddleClick(_ action: @escaping () -> Void) -> some View {
        modifier(MiddleClickModifier(action: action))
    }
}
