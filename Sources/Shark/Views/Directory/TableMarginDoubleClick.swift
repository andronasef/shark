import SwiftUI
import AppKit

/// Double-clicking the empty space below a details table's rows runs `action` (go up one level).
/// SwiftUI's `Table` exposes no background gesture, so this finds the underlying NSTableView.
struct TableMarginDoubleClickModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.overlay(TableMarginRegion(action: action))
    }
}

private struct TableMarginRegion: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> TableMarginNSView {
        let view = TableMarginNSView()
        view.action = action
        return view
    }

    func updateNSView(_ view: TableMarginNSView, context: Context) {
        view.action = action
    }

    static func dismantleNSView(_ view: TableMarginNSView, coordinator: ()) {
        view.stopMonitoring()
    }
}

private final class TableMarginNSView: NSView {
    var action: (() -> Void)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        stopMonitoring()
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, event.clickCount == 2, MouseSetting.marginDoubleClickUp.isEnabled,
                  event.window === self.window,
                  !self.isHiddenOrHasHiddenAncestor,
                  self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil)),
                  let hit = self.window?.contentView?.hitTest(event.locationInWindow),
                  let table = hit.enclosingTableView,
                  table.row(at: table.convert(event.locationInWindow, from: nil)) == -1 else { return event }
            self.action?()
            return nil
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

private extension NSView {
    var enclosingTableView: NSTableView? {
        var view: NSView? = self
        while let current = view {
            if let table = current as? NSTableView { return table }
            view = current.superview
        }
        return nil
    }
}

extension View {
    func onTableMarginDoubleClick(_ action: @escaping () -> Void) -> some View {
        modifier(TableMarginDoubleClickModifier(action: action))
    }
}
