import AppKit
import SwiftUI

public struct CascadingFolderChevronButton: NSViewRepresentable {
    public let url: URL
    public let onNavigate: (URL, Bool) -> Void

    public init(url: URL, onNavigate: @escaping (URL, Bool) -> Void) {
        self.url = url
        self.onNavigate = onNavigate
    }

    public func makeNSView(context: Context) -> NSButton {
        let button = NSButton()
        let config = NSImage.SymbolConfiguration(pointSize: 8, weight: .bold)
        button.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Browse subfolders")?.withSymbolConfiguration(config)
        button.bezelStyle = .inline
        button.isBordered = false
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonClicked(_:))
        button.toolTip = "Browse Subfolders"
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    public func updateNSView(_ nsView: NSButton, context: Context) {
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
