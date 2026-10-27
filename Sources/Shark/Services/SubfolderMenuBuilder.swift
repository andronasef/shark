import AppKit
import Foundation

@MainActor
public final class SubfolderMenuBuilder: NSObject, NSMenuDelegate {
    public typealias NavigationHandler = (_ url: URL, _ inNewTab: Bool) -> Void

    private let navigationHandler: NavigationHandler
    private let showHiddenFiles: Bool
    private var menuURLs: [ObjectIdentifier: URL] = [:]
    // Keep identities alive for this popup's lifetime; addresses can otherwise be reused by submenus.
    private var menus: [ObjectIdentifier: NSMenu] = [:]
    private var loads: [ObjectIdentifier: Task<Void, Never>] = [:]
    private var populated: Set<ObjectIdentifier> = []
    private struct Entry: Sendable { let url: URL; let isDirectory: Bool }

    isolated deinit { for task in loads.values { task.cancel() } }
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
        menus[ObjectIdentifier(menu)] = menu
        let placeholder = NSMenuItem(title: L10n.text("Loading..."), action: nil, keyEquivalent: "")
        placeholder.isEnabled = false
        menu.addItem(placeholder)
        _ = loadTask(for: menu)
        return menu
    }

    public func menuNeedsUpdate(_ menu: NSMenu) {
        _ = loadTask(for: menu)
    }

    /// The same asynchronous loading operation used by the menu delegate.
    func loadContents(of menu: NSMenu) async {
        await loadTask(for: menu)?.value
    }

    private func loadTask(for menu: NSMenu) -> Task<Void, Never>? {
        let id = ObjectIdentifier(menu)
        guard !populated.contains(id), let url = menuURLs[id] else { return nil }
        if let task = loads[id] { return task }
        let hidden = showHiddenFiles
        let task = Task { [weak self, weak menu] in
            let entries = await Self.readEntries(at: url, showHidden: hidden)
            guard !Task.isCancelled, let self, let menu else { return }
            await self.populateMenu(menu, withContentsOf: url, entries: entries)
            if !Task.isCancelled { self.populated.insert(id) }
            self.loads.removeValue(forKey: id)
        }
        loads[id] = task
        return task
    }

    @concurrent private static func readEntries(at url: URL, showHidden: Bool) async -> [Entry]? {
        guard !Task.isCancelled,
              let contents = try? FileManager.default.contentsOfDirectory(at: url,
                includingPropertiesForKeys: [.isDirectoryKey], options: showHidden ? [] : [.skipsHiddenFiles]) else { return nil }
        var entries: [Entry] = []
        entries.reserveCapacity(contents.count)
        for url in contents {
            guard !Task.isCancelled else { return nil }
            entries.append(Entry(url: url, isDirectory: (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false))
        }
        entries.sort { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.url.lastPathComponent.localizedStandardCompare(b.url.lastPathComponent) == .orderedAscending
        }
        return entries
    }

    private func populateMenu(_ menu: NSMenu, withContentsOf dirURL: URL, entries: [Entry]?) async {
        guard let entries, !entries.isEmpty else {
            menu.removeAllItems()
            let empty = NSMenuItem(title: L10n.text(entries == nil ? "(Unable to read)" : "(Empty)"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
            return
        }
        var menuItems: [NSMenuItem] = []
        for (index, entry) in entries.prefix(Self.maxItems).enumerated() {
            if index.isMultiple(of: 16) { await Task.yield() }
            guard !Task.isCancelled else { return }
            let itemURL = entry.url
            let isDir = entry.isDirectory
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
                menus[ObjectIdentifier(submenu)] = submenu

                // Add a dummy placeholder item so the submenu chevron ▸ appears immediately
                let placeholder = NSMenuItem(title: L10n.text("Loading..."), action: nil, keyEquivalent: "")
                placeholder.isEnabled = false
                submenu.addItem(placeholder)

                menuItem.submenu = submenu
            }

            menuItems.append(menuItem)
        }

        if entries.count > Self.maxItems {
            menuItems.append(.separator())
            let more = NSMenuItem(title: L10n.format("Open “%@” to See All %@", L10n.literal(dirURL.lastPathComponent), L10n.items(entries.count)),
                                  action: #selector(menuItemClicked(_:)), keyEquivalent: "")
            more.target = self
            more.representedObject = dirURL
            menuItems.append(more)
        }
        guard !Task.isCancelled else { return }
        menu.removeAllItems()
        for item in menuItems { menu.addItem(item) }
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
