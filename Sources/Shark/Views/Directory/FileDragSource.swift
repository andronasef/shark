import AppKit
import UniformTypeIdentifiers
import SwiftUI

/// Native multi-item dragging writes one file URL per pasteboard item, including for Finder.
/// One shared monitor avoids installing a monitor for every visible grid cell or sidebar row.
@MainActor
private final class FileDragRegistry {
    static let shared = FileDragRegistry()
    private let views = NSHashTable<DragSourceNSView>.weakObjects()
    private weak var candidate: DragSourceNSView?
    private var start = CGPoint.zero
    private var monitor: Any?

    func register(_ view: DragSourceNSView) {
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

/// Sits behind a row or cell without taking clicks; the registry starts its drag.
@MainActor
private class DragSourceNSView: NSView, NSDraggingSource {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { FileDragRegistry.shared.register(self) }
    }
    func startDrag(_ event: NSEvent) {}
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { [] }
}

@MainActor
private final class FileDragNSView: DragSourceNSView {
    var urls: () -> [URL] = { [] }

    override func startDrag(_ event: NSEvent) {
        let payload = urls()
        guard !payload.isEmpty else { return }
        let point = convert(event.locationInWindow, from: nil)
        let fallback = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
        let items = payload.enumerated().map { index, url in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            // Only the front of a pile needs custom artwork; every URL remains in the payload.
            let icon = index < 6 ? NSWorkspace.shared.icon(forFile: url.path) : fallback
            item.setDraggingFrame(CGRect(x: point.x + CGFloat(min(index, 5) * 3), y: point.y, width: 32, height: 32), contents: icon)
            return item
        }
        let session = beginDraggingSession(with: items, event: event, source: self)
        session.draggingFormation = .pile
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { [.copy, .move] }
}

/// A sidebar favorite drags as a shortcut, never as a file, so reordering can't move the folder.
/// Released outside the sidebar with no taker (like Finder), the shortcut is removed.
@MainActor
private final class FavoriteDragNSView: DragSourceNSView {
    var url = URL(fileURLWithPath: "/")
    var onRemove: () -> Void = {}

    override func startDrag(_ event: NSEvent) {
        guard let data = try? JSONEncoder().encode(FavoriteShortcutTransfer(url: url)) else { return }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(UTType.sharkFavorite.identifier))
        let item = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let point = convert(event.locationInWindow, from: nil)
        item.setDraggingFrame(CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20),
                              contents: NSImage(systemSymbolName: "folder", accessibilityDescription: nil))
        let session = beginDraggingSession(with: [item], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .withinApplication ? [.copy, .move, .generic] : []
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        let cancelledWithEscape = NSApp.currentEvent?.type == .keyDown
        // Only sidebar targets use a favorite shortcut; elsewhere SwiftUI may still report a
        // generic operation for the declared type, so the release point decides.
        guard !cancelledWithEscape, let sidebar = enclosingScrollView, let window = sidebar.window else { return }
        let sidebarFrame = window.convertToScreen(sidebar.convert(sidebar.bounds, to: nil))
        guard !sidebarFrame.contains(screenPoint) else { return }
        session.animatesToStartingPositionsOnCancelOrFail = false
        NSAnimationEffect.disappearingItemDefault.show(centeredAt: screenPoint, size: .zero)
        onRemove()
    }
}

private struct FavoriteDragSource: NSViewRepresentable {
    let url: URL
    let onRemove: () -> Void
    func makeNSView(context: Context) -> FavoriteDragNSView { let view = FavoriteDragNSView(); update(view); return view }
    func updateNSView(_ view: FavoriteDragNSView, context: Context) { update(view) }
    private func update(_ view: FavoriteDragNSView) { view.url = url; view.onRemove = onRemove }
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
    func favoriteDragSource(url: URL, onRemove: @escaping () -> Void) -> some View {
        background(FavoriteDragSource(url: url, onRemove: onRemove))
    }

    func fileDragSource(item: FileItem, navigationState: NavigationState, orderedItems: [FileItem]? = nil) -> some View {
        background(FileDragSource {
            let urls = FileDragSelection.urls(dragged: item.url, selected: navigationState.selectedItemIDs,
                                             ordered: (orderedItems ?? navigationState.filteredAndSortedItems).map(\.url))
            if !navigationState.selectedItemIDs.contains(item.url) { navigationState.selectedItemIDs = [item.url] }
            return urls
        })
    }
}
