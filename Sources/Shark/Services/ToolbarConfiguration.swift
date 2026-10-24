import AppKit
import SwiftUI

/// The identifier is also SwiftUI/AppKit's native autosave namespace. AppKit owns storage,
/// defaults, palette presentation and overflow; this bridge never stores a second layout.
enum ToolbarConfiguration {
    static let identifier = "shark-main-toolbar"

    static func locationWidth(availableWidth: CGFloat, otherItemWidths: [CGFloat]) -> CGFloat {
        // Navigation is inseparable from Location (83 pt plus its internal gap). Reserve
        // native group spacing and end margins using the actual installed item count.
        max(100, availableWidth - otherItemWidths.reduce(0, +) - CGFloat(otherItemWidths.count + 1) * 12 - 107)
    }

    static func validatedIdentifiers(_ identifiers: [String], allowed: Set<String>) -> [String] {
        var seen = Set<String>()
        return identifiers.filter { allowed.contains($0) && seen.insert($0).inserted }
    }
}

/// Observes installed items, including overflow items, so narrowing the window cannot
/// create a feedback loop in which the path grows as its neighbours overflow.
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
        private var applying = false
        private var observed = false
        private static let layoutChanged = Notification.Name("SharkNativeToolbarLayoutChanged")

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if !observed {
                observed = true
                NotificationCenter.default.addObserver(self, selector: #selector(itemsChanged(_:)), name: NSToolbar.willAddItemNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(itemsChanged(_:)), name: NSToolbar.didRemoveItemNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(receiveLayout(_:)), name: Self.layoutChanged, object: nil)
            }
            scheduleMeasurement()
        }

        deinit { NotificationCenter.default.removeObserver(self) }

        @objc private func itemsChanged(_ notification: Notification) {
            guard let toolbar = notification.object as? NSToolbar, toolbar === window?.toolbar else { return }
            scheduleMeasurement()
            guard !applying else { return }
            // Item notifications precede the completed native mutation. Broadcast on the
            // next turn, and only after the initial toolbar has been assembled.
            DispatchQueue.main.async { [weak self, weak toolbar] in
                guard let self, let toolbar, self.window?.isVisible == true, !self.applying else { return }
                NotificationCenter.default.post(name: Self.layoutChanged, object: toolbar, userInfo: ["configuration": toolbar.configuration])
            }
        }

        @objc private func receiveLayout(_ notification: Notification) {
            guard let source = notification.object as? NSToolbar,
                  let toolbar = window?.toolbar, source !== toolbar,
                  source.identifier == toolbar.identifier,
                  var configuration = notification.userInfo?["configuration"] as? [String: Any] else { return }
            if let identifiers = configuration["TB Item Identifiers"] as? [String],
               let allowed = toolbar.delegate?.toolbarAllowedItemIdentifiers?(toolbar) {
                configuration["TB Item Identifiers"] = ToolbarConfiguration.validatedIdentifiers(identifiers, allowed: Set(allowed.map(\.rawValue)))
            }
            applying = true
            toolbar.setConfiguration(configuration)
            applying = false
            scheduleMeasurement()
        }

        func scheduleMeasurement() {
            guard !pending else { return }
            pending = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pending = false
                guard let toolbar = self.window?.toolbar else { return }
                toolbar.allowsUserCustomization = true
                toolbar.autosavesConfiguration = true
                let others = toolbar.items.filter {
                    !$0.itemIdentifier.rawValue.contains("navigation-location") &&
                    !$0.itemIdentifier.rawValue.contains("flexible-space") &&
                    $0.itemIdentifier != .flexibleSpace
                }
                let widths = others.map { max($0.view?.fittingSize.width ?? 0, $0.view?.frame.width ?? 0) }
                self.update?(ToolbarConfiguration.locationWidth(availableWidth: self.availableWidth, otherItemWidths: widths))
            }
        }
    }
}
