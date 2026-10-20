import Foundation
import SwiftUI
import AppKit

public struct CommandPaletteItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let iconName: String
    public let category: Category
    public let shortcut: String?
    public let action: @MainActor @Sendable () -> Void

    public enum Category: String, CaseIterable, Sendable {
        case actions = "Actions"
        case navigation = "Places"
        case recent = "Recent Folders"
        case frequent = "Frequent Folders"
        case tabGroups = "Tab Groups"
        case path = "Go to Path"
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        iconName: String,
        category: Category,
        shortcut: String? = nil,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.category = category
        self.shortcut = shortcut
        self.action = action
    }
}

@MainActor
public final class CommandPaletteService {
    public static let shared = CommandPaletteService()

    private init() {}

    /// Generates the full index of available commands for a given workspace state
    public func allItems(for workspace: WorkspaceState) -> [CommandPaletteItem] {
        var items: [CommandPaletteItem] = []
        let nav = workspace.activeNavigationState

        // MARK: - Actions
        items.append(CommandPaletteItem(
            id: "action-toggle-split",
            title: "Toggle Dual Split View",
            subtitle: "Open or close side-by-side pane",
            iconName: "rectangle.split.2x1",
            category: .actions,
            shortcut: "F3 / ⌥⌘S",
            action: { workspace.toggleSplit() }
        ))

        items.append(CommandPaletteItem(
            id: "action-toggle-terminal",
            title: "Toggle Embedded Terminal Drawer",
            subtitle: "Open interactive bottom terminal shell",
            iconName: "terminal",
            category: .actions,
            shortcut: "F4",
            action: { workspace.isTerminalVisible.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-new-tab",
            title: "New Tab",
            subtitle: "Open a new tab at home directory",
            iconName: "plus.rectangle",
            category: .actions,
            shortcut: "⌘T",
            action: { workspace.newTab(placement: .end) }
        ))

        items.append(CommandPaletteItem(
            id: "action-reopen-tab",
            title: "Reopen Closed Tab",
            subtitle: workspace.closedTabs.first?.tab.primary.url.path,
            iconName: "arrow.uturn.backward.circle",
            category: .actions,
            shortcut: "⇧⌘T",
            action: { workspace.reopenClosedTab() }
        ))

        items.append(CommandPaletteItem(
            id: "action-close-tab",
            title: "Close Active Tab",
            subtitle: workspace.activeTab.title,
            iconName: "xmark.square",
            category: .actions,
            shortcut: "⌘W",
            action: { workspace.closeTab(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-duplicate-tab",
            title: "Duplicate Tab",
            subtitle: "Clone current tab and its navigation state",
            iconName: "plus.square.on.square",
            category: .actions,
            action: { workspace.duplicateTab(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-pin-tab",
            title: workspace.activeTab.isPinned ? "Unpin Tab" : "Pin Tab",
            subtitle: "Pin or unpin active tab to the left",
            iconName: workspace.activeTab.isPinned ? "pin.slash" : "pin",
            category: .actions,
            action: { workspace.togglePin(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-lock-tab",
            title: workspace.activeTab.isLocked ? "Unlock Tab" : "Lock Tab",
            subtitle: "Lock tab address or allow navigation",
            iconName: workspace.activeTab.isLocked ? "lock.slash" : "lock",
            category: .actions,
            action: { workspace.toggleLock(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-show-hidden",
            title: nav.showHiddenFiles ? "Hide Hidden Files" : "Show Hidden Files",
            subtitle: "Toggle visibility of dotfiles and hidden folders",
            iconName: "eye",
            category: .actions,
            shortcut: "⇧⌘.",
            action: { nav.showHiddenFiles.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-path-bar",
            title: nav.isBottomPathBarVisible ? "Hide Path Bar" : "Show Path Bar",
            subtitle: "Toggle Finder bottom path bar",
            iconName: "chart.bar.doc.horizontal",
            category: .actions,
            shortcut: "⌥⌘P",
            action: { nav.isBottomPathBarVisible.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-icons",
            title: "View as Icons",
            subtitle: "Grid view mode",
            iconName: "square.grid.2x2",
            category: .actions,
            shortcut: "⌘1",
            action: { nav.viewMode = .grid }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-details",
            title: "View as Details / List",
            subtitle: "Multi-column details table",
            iconName: "list.bullet",
            category: .actions,
            shortcut: "⌘2",
            action: { nav.viewMode = .details }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-compact",
            title: "View as Columns / Compact",
            subtitle: "Compact column browser",
            iconName: "rectangle.split.3x1",
            category: .actions,
            shortcut: "⌘3",
            action: { nav.viewMode = .compact }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-gallery",
            title: "View as Gallery",
            subtitle: "Large visual preview gallery",
            iconName: "macwindow",
            category: .actions,
            shortcut: "⌘4",
            action: { nav.viewMode = .gallery }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-in",
            title: "Zoom In",
            subtitle: "Increase icon and thumbnail size",
            iconName: "plus.magnifyingglass",
            category: .actions,
            shortcut: "⌘+",
            action: { nav.zoomIn() }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-out",
            title: "Zoom Out",
            subtitle: "Decrease icon and thumbnail size",
            iconName: "minus.magnifyingglass",
            category: .actions,
            shortcut: "⌘-",
            action: { nav.zoomOut() }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-reset",
            title: "Actual Size (Reset Zoom)",
            subtitle: "Restore default icon size",
            iconName: "1.magnifyingglass",
            category: .actions,
            shortcut: "⌘0",
            action: { nav.resetZoom() }
        ))

        items.append(CommandPaletteItem(
            id: "action-cut",
            title: "Cut Selected",
            subtitle: "Stage items to move",
            iconName: "scissors",
            category: .actions,
            shortcut: "⌘X",
            action: { nav.cutSelected() }
        ))

        items.append(CommandPaletteItem(
            id: "action-copy",
            title: "Copy Selected",
            subtitle: "Stage items to copy",
            iconName: "doc.on.doc",
            category: .actions,
            shortcut: "⌘C",
            action: { nav.copySelected() }
        ))

        items.append(CommandPaletteItem(
            id: "action-paste",
            title: "Paste",
            subtitle: "Paste files into current folder",
            iconName: "doc.on.clipboard",
            category: .actions,
            shortcut: "⌘V",
            action: { Task { await nav.paste() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-undo",
            title: "Undo: \(FileUndoService.shared.currentUndoDescription ?? "Last Action")",
            subtitle: "Revert the last file operation",
            iconName: "arrow.uturn.backward",
            category: .actions,
            shortcut: "⌘Z",
            action: { Task { await nav.undo() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-redo",
            title: "Redo: \(FileUndoService.shared.currentRedoDescription ?? "Last Action")",
            subtitle: "Reapply previously undone operation",
            iconName: "arrow.uturn.forward",
            category: .actions,
            shortcut: "⇧⌘Z",
            action: { Task { await nav.redo() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-select-all",
            title: "Select All",
            subtitle: "Select all items in folder",
            iconName: "checklist",
            category: .actions,
            shortcut: "⌘A",
            action: { nav.selectedItemIDs = Set(nav.items.map(\.url)) }
        ))

        items.append(CommandPaletteItem(
            id: "action-copy-path",
            title: "Copy Current Path",
            subtitle: nav.currentURL.path,
            iconName: "doc.text",
            category: .actions,
            shortcut: "⌥⌘C",
            action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(nav.currentURL.path, forType: .string)
            }
        ))

        items.append(CommandPaletteItem(
            id: "action-calculate-sizes",
            title: "Calculate All Folder Sizes",
            subtitle: "Compute recursive directory sizes in background",
            iconName: "scalemass",
            category: .actions,
            action: {
                for item in nav.items where item.isDirectory {
                    FolderSizeCalculator.shared.requestSize(for: item.url)
                }
            }
        ))

        items.append(CommandPaletteItem(
            id: "action-new-folder",
            title: "New Folder",
            subtitle: "Create a new folder in current directory",
            iconName: "folder.badge.plus",
            category: .actions,
            shortcut: "⇧⌘N",
            action: { nav.requestedNewItemType = .folder }
        ))

        items.append(CommandPaletteItem(
            id: "action-new-file",
            title: "New File",
            subtitle: "Create an empty file in current directory",
            iconName: "doc.badge.plus",
            category: .actions,
            action: { nav.requestedNewItemType = .file }
        ))

        // MARK: - Places / Navigation
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Desktop")
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Documents")
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? home.appendingPathComponent("Downloads")
        let applications = URL(fileURLWithPath: "/Applications")
        let root = URL(fileURLWithPath: "/")

        items.append(CommandPaletteItem(
            id: "place-home",
            title: "Home",
            subtitle: home.path,
            iconName: "house",
            category: .navigation,
            shortcut: "⇧⌘H",
            action: { nav.navigateTo(home) }
        ))

        items.append(CommandPaletteItem(
            id: "place-desktop",
            title: "Desktop",
            subtitle: desktop.path,
            iconName: "desktopcomputer",
            category: .navigation,
            shortcut: "⌥⌘D",
            action: { nav.navigateTo(desktop) }
        ))

        items.append(CommandPaletteItem(
            id: "place-documents",
            title: "Documents",
            subtitle: documents.path,
            iconName: "doc.text",
            category: .navigation,
            shortcut: "⌥⌘O",
            action: { nav.navigateTo(documents) }
        ))

        items.append(CommandPaletteItem(
            id: "place-downloads",
            title: "Downloads",
            subtitle: downloads.path,
            iconName: "arrow.down.circle",
            category: .navigation,
            shortcut: "⌥⌘L",
            action: { nav.navigateTo(downloads) }
        ))

        items.append(CommandPaletteItem(
            id: "place-apps",
            title: "Applications",
            subtitle: applications.path,
            iconName: "app.badge",
            category: .navigation,
            shortcut: "⇧⌘A",
            action: { nav.navigateTo(applications) }
        ))

        items.append(CommandPaletteItem(
            id: "place-root",
            title: "Macintosh HD",
            subtitle: "/",
            iconName: "internaldrive",
            category: .navigation,
            shortcut: "⇧⌘C",
            action: { nav.navigateTo(root) }
        ))

        // MARK: - Recent Folders
        for (idx, url) in RecentFoldersService.shared.recentFolders.prefix(8).enumerated() {
            items.append(CommandPaletteItem(
                id: "recent-\(idx)-\(url.path)",
                title: url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent,
                subtitle: url.path,
                iconName: "clock.arrow.circlepath",
                category: .recent,
                action: { nav.navigateTo(url) }
            ))
        }

        // MARK: - Frequent Folders
        for (idx, url) in RecentFoldersService.shared.frequentFolders.prefix(6).enumerated() {
            items.append(CommandPaletteItem(
                id: "frequent-\(idx)-\(url.path)",
                title: url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent,
                subtitle: url.path,
                iconName: "flame",
                category: .frequent,
                action: { nav.navigateTo(url) }
            ))
        }

        // MARK: - Tab Groups
        for group in TabGroupService.shared.groups {
            items.append(CommandPaletteItem(
                id: "tabgroup-\(group.id)",
                title: "Restore Group: \(group.name)",
                subtitle: "\(group.tabs.count) tabs (\(group.tabs.map { URL(fileURLWithPath: $0.primaryPath).lastPathComponent }.joined(separator: ", ")))",
                iconName: "square.stack.3d.up",
                category: .tabGroups,
                action: { TabGroupService.shared.restore(group: group, into: workspace, replace: false) }
            ))
        }

        return items
    }

    /// Filters and ranks items based on user query
    public func filter(query: String, for workspace: WorkspaceState) -> [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Path navigation mode (starts with / or ~)
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            let expandedPath = (trimmed as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            var exists = false
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                exists = true
            }

            let pathItem = CommandPaletteItem(
                id: "custom-path-navigate",
                title: "Go to: \(trimmed)",
                subtitle: exists ? (isDir.boolValue ? "Directory exists" : "File exists") : "Path: \(expandedPath)",
                iconName: isDir.boolValue ? "folder" : "arrow.right.circle",
                category: .path,
                shortcut: "↵",
                action: {
                    workspace.activeNavigationState.navigateTo(url)
                }
            )
            return [pathItem]
        }

        let all = allItems(for: workspace)
        if trimmed.isEmpty {
            return all
        }

        let lower = trimmed.lowercased()

        // Score based filtering
        var scored: [(item: CommandPaletteItem, score: Int)] = []

        for item in all {
            let titleLower = item.title.lowercased()
            let subtitleLower = (item.subtitle ?? "").lowercased()

            var score = 0
            if titleLower == lower {
                score += 1000
            } else if titleLower.hasPrefix(lower) {
                score += 500
            } else if titleLower.contains(lower) {
                score += 200
            } else if subtitleLower.contains(lower) {
                score += 80
            } else if fuzzyMatches(query: lower, target: titleLower) {
                score += 50
            }

            if score > 0 {
                scored.append((item, score))
            }
        }

        return scored
            .sorted { $0.score > $1.score }
            .map(\.item)
    }

    private func fuzzyMatches(query: String, target: String) -> Bool {
        var targetIndex = target.startIndex
        for char in query {
            guard let foundIndex = target[targetIndex...].firstIndex(of: char) else {
                return false
            }
            targetIndex = target.index(after: foundIndex)
        }
        return true
    }
}
