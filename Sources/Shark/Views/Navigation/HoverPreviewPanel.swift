import SwiftUI
import AppKit

private struct PreviewSizeKey: PreferenceKey {
    static let defaultValue = CGSize.zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) { value = nextValue() }
}

private struct HoverPreviewPanelRoot: View {
    let item: FileItem
    let availableSize: CGSize
    let onSize: (CGSize) -> Void

    var body: some View {
        HoverPreviewCard(item: item, availableSize: availableSize)
            .frame(maxWidth: min(480, availableSize.width), maxHeight: availableSize.height)
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
final class HoverPreviewPanel: NSObject, NSWindowDelegate {
    static let shared = HoverPreviewPanel()

    private(set) var isMouseInside = false
    private var panel: NSPanel?
    private var anchor = NSPoint.zero
    private var ownerURL: URL?
    private var onDismiss: (() -> Void)?
    private var isRepositioning = false

    private override init() {
        super.init()
    }

    /// Shows the preview beside the pointer. `onDismiss` runs when the pointer leaves the panel.
    func show(_ item: FileItem, onDismiss: @escaping () -> Void) {
        anchor = NSEvent.mouseLocation
        ownerURL = item.url
        self.onDismiss = onDismiss
        isMouseInside = false

        let bounds = screenBounds
        let generation = UUID()
        self.generation = generation
        let view = TrackingHostingView(rootView: HoverPreviewPanelRoot(item: item, availableSize: bounds.size) { [weak self] size in
            guard self?.generation == generation else { return }
            self?.fit(size)
        })
        view.onHoverChange = { [weak self] inside in
            self?.isMouseInside = inside
            if !inside { self?.onDismiss?() }
        }
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.contentView = view
        let initialFitting = view.fittingSize
        let size = (initialFitting.width > 0 && initialFitting.height > 0) ? initialFitting : CGSize(width: 264, height: 144)
        place(panel, size: size)
        panel.orderFrontRegardless()
        // Backstop: after the first layout pass, make sure nothing left the usable screen.
        DispatchQueue.main.async { [weak self, weak panel] in
            guard let self, let panel, panel.isVisible, self.generation == generation else { return }
            self.place(panel, size: panel.frame.size)
        }
    }

    /// No-op unless `url` still owns the panel, so a stale row can't close a newer preview.
    func hide(ownerURL url: URL) {
        guard ownerURL == url else { return }
        ownerURL = nil
        generation = nil
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
        panel.delegate = self
        NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.onDismiss?() }
        }
        // A display was added, removed, resized or its Dock/menu bar moved: refit to the new bounds.
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let panel = self.panel, panel.isVisible else { return }
                self.place(panel, size: panel.frame.size)
            }
        }
        return panel
    }

    nonisolated func windowDidResize(_ notification: Notification) {
        Task { @MainActor in
            guard !self.isRepositioning, let panel = self.panel, panel.isVisible else { return }
            self.isRepositioning = true
            let targetFrame = PreviewPlacement.frame(anchor: self.anchor, desiredSize: panel.frame.size, visibleFrame: self.screenBounds)
            if panel.frame != targetFrame {
                panel.setFrame(targetFrame, display: true)
            }
            self.isRepositioning = false
        }
    }

    private func fit(_ size: CGSize) {
        guard let panel, panel.isVisible, size.width > 0, size.height > 0 else { return }
        place(panel, size: size)
    }

    private func place(_ panel: NSPanel, size: CGSize) {
        panel.setFrame(PreviewPlacement.frame(anchor: anchor, desiredSize: size, visibleFrame: screenBounds), display: true)
    }

    private var generation: UUID?
    private var screenBounds: CGRect {
        (NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main)?.visibleFrame ?? CGRect(x: 0, y: 0, width: 800, height: 600)
    }
}
