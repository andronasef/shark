import AppKit
import SwiftUI

/// The identifier is also SwiftUI/AppKit's native autosave namespace. AppKit owns storage,
/// defaults, palette presentation, display mode and overflow; Shark only names its items and
/// sizes the Location capsule. Only public NSToolbar/NSToolbarItem API is used here: replacing
/// SwiftUI's toolbar delegate or restyling AppKit's private views crashed item insertion.
enum ToolbarConfiguration {
    static let identifier = "shark-main-toolbar"

    static func itemLabel(for identifier: String) -> String? {
        switch identifier {
        case "navigation-location": L10n.text("Location")
        case "path": L10n.text("Path")
        case "view-mode": L10n.text("View")
        case "group-sort": L10n.text("Group")
        case "share": L10n.text("Share")
        case "split": L10n.text("Split")
        case "terminal": L10n.text("Terminal")
        case "actions": L10n.text("Action")
        case "search": L10n.text("Search")
        default: nil
        }
    }

    /// Native labels drive both "Icon Only" and "Icon and Text" display modes.
    @MainActor
    static func applyLabel(to item: NSToolbarItem) {
        guard let label = itemLabel(for: item.itemIdentifier.rawValue) else { return }
        if item.label != label { item.label = label }
        if item.paletteLabel != label { item.paletteLabel = label }
    }

    static func locationWidth(availableWidth: CGFloat, otherItemWidths: [CGFloat]) -> CGFloat {
        // Navigation is inseparable from Location (83 pt plus its internal gap). Reserve
        // native group spacing and end margins using the actual installed item count.
        max(100, availableWidth - otherItemWidths.reduce(0, +) - CGFloat(otherItemWidths.count + 1) * 12 - 107)
    }
}

/// Labels installed items and measures them, including overflow items, so narrowing the window
/// cannot create a feedback loop in which the path grows as its neighbours overflow.
struct ToolbarLayoutObserver: NSViewRepresentable {
    var availableWidth: CGFloat
    @Binding var locationWidth: CGFloat

    func makeNSView(context: Context) -> Probe {
        let view = Probe()
        view.update = { [binding = $locationWidth] width in
            if abs(binding.wrappedValue - width) > 1 { binding.wrappedValue = width }
        }
        view.availableWidth = availableWidth
        return view
    }

    func updateNSView(_ view: Probe, context: Context) {
        view.availableWidth = availableWidth
        view.scheduleMeasurement()
    }

    @MainActor final class Probe: NSView {
        var availableWidth: CGFloat = 1000
        var update: ((CGFloat) -> Void)?
        private var pending = false
        private var observing = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if !observing {
                observing = true
                for name in [NSToolbar.willAddItemNotification, NSToolbar.didRemoveItemNotification] {
                    NotificationCenter.default.addObserver(self, selector: #selector(itemsChanged(_:)), name: name, object: nil)
                }
            }
            scheduleMeasurement()
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        @objc private func itemsChanged(_ notification: Notification) {
            guard let toolbar = notification.object as? NSToolbar, toolbar === window?.toolbar else { return }
            if let item = notification.userInfo?["item"] as? NSToolbarItem { ToolbarConfiguration.applyLabel(to: item) }
            scheduleMeasurement()
        }

        func scheduleMeasurement() {
            guard !pending else { return }
            pending = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pending = false
                guard let toolbar = self.window?.toolbar else { return }
                if !toolbar.allowsUserCustomization { toolbar.allowsUserCustomization = true }
                if !toolbar.autosavesConfiguration { toolbar.autosavesConfiguration = true }
                if #available(macOS 15.0, *), !toolbar.allowsDisplayModeCustomization {
                    toolbar.allowsDisplayModeCustomization = true
                }
                toolbar.items.forEach(ToolbarConfiguration.applyLabel(to:))
                let others = toolbar.items.filter {
                    $0.itemIdentifier.rawValue != "navigation-location" && $0.itemIdentifier.rawValue != "flexible-space"
                        && $0.itemIdentifier != .flexibleSpace && $0.itemIdentifier != .space
                }
                let widths = others.map { max($0.view?.fittingSize.width ?? 0, $0.view?.frame.width ?? 0) }
                self.update?(ToolbarConfiguration.locationWidth(availableWidth: self.availableWidth, otherItemWidths: widths))
            }
        }
    }
}
