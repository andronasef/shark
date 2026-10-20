import AppKit
import SwiftUI

public struct CascadingFolderChevronButton: NSViewRepresentable {
    public let url: URL
    public var symbol: String
    public var pointSize: CGFloat
    public let onNavigate: (URL, Bool) -> Void

    public init(url: URL, symbol: String = "chevron.down", pointSize: CGFloat = 8, onNavigate: @escaping (URL, Bool) -> Void) {
        self.url = url
        self.symbol = symbol
        self.pointSize = pointSize
        self.onNavigate = onNavigate
    }

    public func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Browse subfolders")?.withSymbolConfiguration(config)
        button.bezelStyle = .inline
        button.isBordered = false
        button.contentTintColor = .labelColor
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonClicked(_:))
        button.toolTip = "Browse Subfolders"
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    public func updateNSView(_ nsView: NSButton, context: Context) {
        nsView.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Browse subfolders")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold))
        nsView.toolTip = "Browse subfolders of \(url.lastPathComponent.isEmpty ? "Macintosh HD" : url.lastPathComponent)"
        context.coordinator.url = url
        context.coordinator.onNavigate = onNavigate
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(url: url, onNavigate: onNavigate)
    }

    @MainActor
    public final class Coordinator: NSObject {
        var url: URL
        var onNavigate: (URL, Bool) -> Void
        private var menuBuilder: SubfolderMenuBuilder?

        init(url: URL, onNavigate: @escaping (URL, Bool) -> Void) {
            self.url = url
            self.onNavigate = onNavigate
            super.init()
        }

        @objc func buttonClicked(_ sender: NSButton) {
            let builder = SubfolderMenuBuilder { [weak self] targetURL, inNewTab in
                self?.onNavigate(targetURL, inNewTab)
            }
            self.menuBuilder = builder
            let menu = builder.buildMenu(for: url)

            let location = NSPoint(x: 0, y: sender.bounds.height + 4)
            menu.popUp(positioning: nil, at: location, in: sender)
        }
    }
}
