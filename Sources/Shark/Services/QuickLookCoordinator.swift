import AppKit
@preconcurrency import QuickLookUI

public final class QuickLookCoordinator: NSObject, Sendable {
    public static let shared = QuickLookCoordinator()

    @MainActor
    public private(set) var previewURLs: [URL] = []

    private override init() {
        super.init()
    }

    @MainActor
    public func toggleQuickLook(for urls: [URL]) {
        guard let panel = QLPreviewPanel.shared() else { return }

        if panel.isVisible && previewURLs == urls {
            panel.orderOut(nil)
            return
        }

        self.previewURLs = urls
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    @MainActor
    public func updateQuickLook(urls: [URL]) {
        self.previewURLs = urls
        if let panel = QLPreviewPanel.shared(), panel.isVisible {
            panel.reloadData()
        }
    }
}

extension QuickLookCoordinator: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public func numberOfPreviewItems(in panel: QLPreviewPanel?) -> Int {
        MainActor.assumeIsolated {
            previewURLs.count
        }
    }

    public func previewPanel(_ panel: QLPreviewPanel?, previewItemAt index: Int) -> (any QLPreviewItem)? {
        MainActor.assumeIsolated {
            guard index >= 0 && index < previewURLs.count else { return nil }
            return previewURLs[index] as NSURL
        }
    }
}
