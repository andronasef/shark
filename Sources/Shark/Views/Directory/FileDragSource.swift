import AppKit
import SwiftUI

/// Native multi-item dragging writes one file URL per pasteboard item, including for Finder.
/// One shared monitor avoids installing a monitor for every visible grid cell.
@MainActor
private final class FileDragRegistry {
    static let shared = FileDragRegistry()
    private let views = NSHashTable<FileDragNSView>.weakObjects()
    private weak var candidate: FileDragNSView?
    private var start = CGPoint.zero
    private var monitor: Any?

    func register(_ view: FileDragNSView) {
        views.add(view)
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handle(event) ?? event
        }
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .leftMouseDown:
            candidate = views.allObjects.first { view in
                guard view.window === event.window, !view.isHiddenOrHasHiddenAncestor else { return false }
                // SwiftUI hosts report a bogus, far larger visibleRect, so test the real bounds and
                // then the enclosing scroll view's visible area (cells can sit partly scrolled away).
                let point = view.convert(event.locationInWindow, from: nil)
                guard view.bounds.contains(point) else { return false }
                guard let scroll = view.enclosingScrollView else { return true }
                return scroll.documentVisibleRect.contains(view.convert(point, to: scroll.documentView))
            }
            start = event.locationInWindow
        case .leftMouseUp: candidate = nil
        case .leftMouseDragged:
            guard let source = candidate,
                  hypot(event.locationInWindow.x - start.x, event.locationInWindow.y - start.y) > 5 else { return event }
            candidate = nil
            source.startDrag(event)
            return nil
        default: break
        }
        return event
    }
}

@MainActor
private final class FileDragNSView: NSView, NSDraggingSource {
    var urls: () -> [URL] = { [] }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { FileDragRegistry.shared.register(self) }
    }

    func startDrag(_ event: NSEvent) {
        let payload = urls()
        guard !payload.isEmpty else { return }
        let point = convert(event.locationInWindow, from: nil)
        let items = payload.enumerated().map { index, url in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            item.setDraggingFrame(CGRect(x: point.x + CGFloat(min(index, 5) * 3), y: point.y, width: 32, height: 32), contents: icon)
            return item
        }
        let session = beginDraggingSession(with: items, event: event, source: self)
        session.draggingFormation = .pile
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { [.copy, .move] }
}

private struct FileDragSource: NSViewRepresentable {
    let urls: () -> [URL]
    func makeNSView(context: Context) -> FileDragNSView {
        let view = FileDragNSView()
        view.urls = urls
        return view
    }
    func updateNSView(_ view: FileDragNSView, context: Context) { view.urls = urls }
}

extension View {
    func fileDragSource(item: FileItem, navigationState: NavigationState, orderedItems: [FileItem]? = nil) -> some View {
        background(FileDragSource {
            let urls = FileDragSelection.urls(dragged: item.url, selected: navigationState.selectedItemIDs,
                                             ordered: (orderedItems ?? navigationState.filteredAndSortedItems).map(\.url))
            if !navigationState.selectedItemIDs.contains(item.url) { navigationState.selectedItemIDs = [item.url] }
            return urls
        })
    }
}
