import AppKit
import Foundation

@MainActor
public final class SubfolderMenuBuilder: NSObject, NSMenuDelegate {
    public typealias NavigationHandler = (_ url: URL, _ inNewTab: Bool) -> Void

    private let navigationHandler: NavigationHandler
    private let showHiddenFiles: Bool
    private var menuURLs: [ObjectIdentifier: URL] = [:]
    /// Menus past this size take seconds to build and are unusable anyway.
    static let maxItems = 500

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
        let entries = contents.map { url in
            (url: url, isDir: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
        }
        let sorted = entries.sorted { a, b in
            if a.isDir != b.isDir {
                return a.isDir
            }
            return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
        }

        for (itemURL, isDir) in sorted.prefix(Self.maxItems) {
            let displayName = itemURL.lastPathComponent

            let menuItem = NSMenuItem(
                title: displayName,
                action: #selector(menuItemClicked(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = itemURL
            menuItem.toolTip = isDir
                ? "Click to open · ⌘-click opens in a new tab · ⌥-click copies"
                : "Click to open · ⌥-click copies"

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

        if sorted.count > Self.maxItems {
            menu.addItem(.separator())
            let more = NSMenuItem(title: "Open “\(dirURL.lastPathComponent)” to See All \(sorted.count) Items",
                                  action: #selector(menuItemClicked(_:)), keyEquivalent: "")
            more.target = self
            more.representedObject = dirURL
            menu.addItem(more)
        }
    }

    @objc private func menuItemClicked(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        activate(url, modifiers: NSEvent.modifierFlags)
    }

    /// ⌥ copies the item to the file clipboard (⌘V in any pane pastes it), ⌘ opens a folder in a
    /// new tab, and a plain click opens it.
    func activate(_ url: URL, modifiers: NSEvent.ModifierFlags) {
        if modifiers.contains(.option) {
            FileClipboardService.shared.copy([url])
            return
        }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            navigationHandler(url, modifiers.contains(.command))
        } else {
            // It's a file: open with default app
            NSWorkspace.shared.open(url)
        }
    }
}
