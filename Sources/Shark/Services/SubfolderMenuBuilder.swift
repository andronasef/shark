import AppKit
import Foundation

@MainActor
public final class SubfolderMenuBuilder: NSObject, NSMenuDelegate {
    public typealias NavigationHandler = (_ url: URL, _ inNewTab: Bool) -> Void

    private let navigationHandler: NavigationHandler
    private let showHiddenFiles: Bool
    private var menuURLs: [ObjectIdentifier: URL] = [:]

    public init(showHiddenFiles: Bool = false, onNavigate: @escaping NavigationHandler) {
        self.showHiddenFiles = showHiddenFiles
        self.navigationHandler = onNavigate
        super.init()
    }

    public func buildMenu(for url: URL, title: String? = nil) -> NSMenu {
        let menu = NSMenu(title: title ?? url.lastPathComponent)
        menu.delegate = self
        menu.autoenablesItems = false
        menuURLs[ObjectIdentifier(menu)] = url
        populateMenu(menu, withContentsOf: url)
        return menu
    }

    public func menuNeedsUpdate(_ menu: NSMenu) {
        guard let url = menuURLs[ObjectIdentifier(menu)] else { return }
        populateMenu(menu, withContentsOf: url)
    }

    private func populateMenu(_ menu: NSMenu, withContentsOf dirURL: URL) {
        menu.removeAllItems()

        let fm = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = showHiddenFiles ? [] : [.skipsHiddenFiles]

        guard let contents = try? fm.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: [.isDirectoryKey, .localizedNameKey],
            options: options
        ) else {
            let emptyItem = NSMenuItem(title: "(Unable to read)", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            return
        }

        if contents.isEmpty {
            let emptyItem = NSMenuItem(title: "(Empty)", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            return
        }

        // Sort: folders first, then alphabetically
        let sorted = contents.sorted { a, b in
            let aIsDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bIsDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if aIsDir != bIsDir {
                return aIsDir && !bIsDir
            }
            return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
        }

        for itemURL in sorted {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let displayName = itemURL.lastPathComponent

            let menuItem = NSMenuItem(
                title: displayName,
                action: #selector(menuItemClicked(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = itemURL

            // Icon
            let icon = NSWorkspace.shared.icon(forFile: itemURL.path)
            icon.size = NSSize(width: 16, height: 16)
            menuItem.image = icon

            if isDir {
                // Attach a submenu for cascading navigation
                let submenu = NSMenu(title: displayName)
                submenu.delegate = self
                menuURLs[ObjectIdentifier(submenu)] = itemURL

                // Add a dummy placeholder item so the submenu chevron ▸ appears immediately
                let placeholder = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
                placeholder.isEnabled = false
                submenu.addItem(placeholder)

                menuItem.submenu = submenu
            }

            menu.addItem(menuItem)
        }
    }

    @objc private func menuItemClicked(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        let isCmdPressed = NSEvent.modifierFlags.contains(.command)

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            navigationHandler(url, isCmdPressed)
        } else {
            // It's a file: open with default app
            NSWorkspace.shared.open(url)
        }
    }
}
