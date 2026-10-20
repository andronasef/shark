import SwiftUI
import AppKit

private struct PreviewSizeKey: PreferenceKey {
    static let defaultValue = CGSize.zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private struct HoverPreviewPanelRoot: View {
    let item: FileItem
    let onSize: (CGSize) -> Void

    var body: some View {
        HoverPreviewCard(item: item)
            .frame(maxWidth: 480)
            .fixedSize()
            .background(GeometryReader { Color.clear.preference(key: PreviewSizeKey.self, value: $0.size) })
            .onPreferenceChange(PreviewSizeKey.self, perform: onSize)
    }
}

/// Reports pointer entry/exit even though the panel is never the key window.
private final class TrackingHostingView: NSHostingView<HoverPreviewPanelRoot> {
    var onHoverChange: ((Bool) -> Void)?
    private var area: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area { removeTrackingArea(area) }
        let new = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self)
        addTrackingArea(new)
        area = new
    }

    override func mouseEntered(with event: NSEvent) { onHoverChange?(true) }
    override func mouseExited(with event: NSEvent) { onHoverChange?(false) }
}

/// One floating, non-activating preview shared by every row. Because it can never become key,
/// showing it leaves keyboard focus (rename fields, the terminal, another app) untouched.
@MainActor
final class HoverPreviewPanel {
    static let shared = HoverPreviewPanel()

    private(set) var isMouseInside = false
    private var panel: NSPanel?
    private var anchor = NSPoint.zero
    private var ownerURL: URL?
    private var onDismiss: (() -> Void)?

    private init() {}

    /// Shows the preview beside the pointer. `onDismiss` runs when the pointer leaves the panel.
    func show(_ item: FileItem, onDismiss: @escaping () -> Void) {
        anchor = NSEvent.mouseLocation
        ownerURL = item.url
        self.onDismiss = onDismiss
        isMouseInside = false

        let view = TrackingHostingView(rootView: HoverPreviewPanelRoot(item: item) { [weak self] in self?.fit($0) })
        view.sizingOptions = []
        view.onHoverChange = { [weak self] inside in
            self?.isMouseInside = inside
            if !inside { self?.onDismiss?() }
        }
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = view
        place(panel, size: view.fittingSize)
        panel.orderFrontRegardless()
    }

    /// No-op unless `url` still owns the panel, so a stale row can't close a newer preview.
    func hide(ownerURL url: URL) {
        guard ownerURL == url else { return }
        ownerURL = nil
        onDismiss = nil
        isMouseInside = false
        panel?.orderOut(nil)
        panel?.contentView = nil // tears down the content, which stops any media playback
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onDismiss?() }
        }
        return panel
    }

    private func fit(_ size: CGSize) {
        guard let panel, panel.isVisible, size.width > 0, size.height > 0 else { return }
        place(panel, size: size)
    }

    private func place(_ panel: NSPanel, size: CGSize) {
        let bounds = (NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main)?.visibleFrame ?? .zero
        let gap: CGFloat = 16
        var x = anchor.x + gap
        if x + size.width > bounds.maxX { x = anchor.x - gap - size.width }
        let y = max(bounds.minY, min(anchor.y - gap - size.height, bounds.maxY - size.height))
        panel.setFrame(NSRect(x: max(bounds.minX, x), y: y, width: size.width, height: size.height), display: true)
    }
}
