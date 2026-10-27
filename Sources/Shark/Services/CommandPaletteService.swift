import Foundation
import Observation
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
            title: L10n.text("Toggle Dual Split View"),
            subtitle: L10n.text("Open or close side-by-side pane"),
            iconName: "rectangle.split.2x1",
            category: .actions,
            shortcut: "F3 / ⌥⌘S",
            action: { workspace.toggleSplit() }
        ))

        items.append(CommandPaletteItem(
            id: "action-toggle-terminal",
            title: L10n.text("Toggle Embedded Terminal Drawer"),
            subtitle: L10n.text("Open interactive bottom terminal shell"),
            iconName: "terminal",
            category: .actions,
            shortcut: "F4",
            action: { workspace.isTerminalVisible.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-new-tab",
            title: L10n.text("New Tab"),
            subtitle: L10n.text("Open a new tab at home directory"),
            iconName: "plus.rectangle",
            category: .actions,
            shortcut: "⌘T",
            action: { workspace.newTab(placement: .end) }
        ))

        items.append(CommandPaletteItem(
            id: "action-reopen-tab",
            title: L10n.text("Reopen Closed Tab"),
            subtitle: workspace.closedTabs.first?.tab.primary.url.path,
            iconName: "arrow.uturn.backward.circle",
            category: .actions,
            shortcut: "⇧⌘T",
            action: { workspace.reopenClosedTab() }
        ))

        items.append(CommandPaletteItem(
            id: "action-close-tab",
            title: L10n.text("Close Active Tab"),
            subtitle: workspace.activeTab.title,
            iconName: "xmark.square",
            category: .actions,
            shortcut: "⌘W",
            action: { workspace.closeTab(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-duplicate-tab",
            title: L10n.text("Duplicate Tab"),
            subtitle: L10n.text("Clone current tab and its navigation state"),
            iconName: "plus.square.on.square",
            category: .actions,
            action: { workspace.duplicateTab(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-pin-tab",
            title: workspace.activeTab.isPinned ? L10n.text("Unpin Tab") : L10n.text("Pin Tab"),
            subtitle: L10n.text("Pin or unpin active tab to the left"),
            iconName: workspace.activeTab.isPinned ? "pin.slash" : "pin",
            category: .actions,
            action: { workspace.togglePin(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-lock-tab",
            title: workspace.activeTab.isLocked ? L10n.text("Unlock Tab") : L10n.text("Lock Tab"),
            subtitle: L10n.text("Lock tab address or allow navigation"),
            iconName: workspace.activeTab.isLocked ? "lock.slash" : "lock",
            category: .actions,
            action: { workspace.toggleLock(id: workspace.activeTabID) }
        ))

        items.append(CommandPaletteItem(
            id: "action-show-hidden",
            title: nav.showHiddenFiles ? L10n.text("Hide Hidden Files") : L10n.text("Show Hidden Files"),
            subtitle: L10n.text("Toggle visibility of dotfiles and hidden folders"),
            iconName: "eye",
            category: .actions,
            shortcut: "⇧⌘.",
            action: { nav.showHiddenFiles.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-path-bar",
            title: nav.isBottomPathBarVisible ? L10n.text("Hide Path Bar") : L10n.text("Show Path Bar"),
            subtitle: L10n.text("Toggle Finder bottom path bar"),
            iconName: "chart.bar.doc.horizontal",
            category: .actions,
            shortcut: "⌥⌘P",
            action: { nav.isBottomPathBarVisible.toggle() }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-icons",
            title: L10n.text("View as Icons"),
            subtitle: L10n.text("Grid view mode"),
            iconName: "square.grid.2x2",
            category: .actions,
            shortcut: "⌘1",
            action: { nav.viewMode = .grid }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-details",
            title: L10n.text("View as Details / List"),
            subtitle: L10n.text("Multi-column details table"),
            iconName: "list.bullet",
            category: .actions,
            shortcut: "⌘2",
            action: { nav.viewMode = .details }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-compact",
            title: L10n.text("View as Columns / Compact"),
            subtitle: L10n.text("Compact column browser"),
            iconName: "rectangle.split.3x1",
            category: .actions,
            shortcut: "⌘3",
            action: { nav.viewMode = .compact }
        ))

        items.append(CommandPaletteItem(
            id: "action-view-gallery",
            title: L10n.text("View as Gallery"),
            subtitle: L10n.text("Large visual preview gallery"),
            iconName: "macwindow",
            category: .actions,
            shortcut: "⌘4",
            action: { nav.viewMode = .gallery }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-in",
            title: L10n.text("Zoom In"),
            subtitle: L10n.text("Increase icon and thumbnail size"),
            iconName: "plus.magnifyingglass",
            category: .actions,
            shortcut: "⌘+",
            action: { nav.zoomIn() }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-out",
            title: L10n.text("Zoom Out"),
            subtitle: L10n.text("Decrease icon and thumbnail size"),
            iconName: "minus.magnifyingglass",
            category: .actions,
            shortcut: "⌘-",
            action: { nav.zoomOut() }
        ))

        items.append(CommandPaletteItem(
            id: "action-zoom-reset",
            title: L10n.text("Actual Size (Reset Zoom)"),
            subtitle: L10n.text("Restore default icon size"),
            iconName: "1.magnifyingglass",
            category: .actions,
            shortcut: "⌘0",
            action: { nav.resetZoom() }
        ))

        items.append(CommandPaletteItem(
            id: "action-cut",
            title: L10n.text("Cut Selected"),
            subtitle: L10n.text("Stage items to move"),
            iconName: "scissors",
            category: .actions,
            shortcut: "⌘X",
            action: { nav.cutSelected() }
        ))

        items.append(CommandPaletteItem(
            id: "action-copy",
            title: L10n.text("Copy Selected"),
            subtitle: L10n.text("Stage items to copy"),
            iconName: "doc.on.doc",
            category: .actions,
            shortcut: "⌘C",
            action: { nav.copySelected() }
        ))

        items.append(CommandPaletteItem(
            id: "action-paste",
            title: L10n.text("Paste"),
            subtitle: L10n.text("Paste files into current folder"),
            iconName: "doc.on.clipboard",
            category: .actions,
            shortcut: "⌘V",
            action: { Task { await nav.paste() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-undo",
            title: L10n.format("Undo: %@", FileUndoService.shared.currentUndoDescription ?? L10n.text("Last Action")),
            subtitle: L10n.text("Revert the last file operation"),
            iconName: "arrow.uturn.backward",
            category: .actions,
            shortcut: "⌘Z",
            action: { Task { await nav.undo() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-redo",
            title: L10n.format("Redo: %@", FileUndoService.shared.currentRedoDescription ?? L10n.text("Last Action")),
            subtitle: L10n.text("Reapply previously undone operation"),
            iconName: "arrow.uturn.forward",
            category: .actions,
            shortcut: "⇧⌘Z",
            action: { Task { await nav.redo() } }
        ))

        items.append(CommandPaletteItem(
            id: "action-select-all",
            title: L10n.text("Select All"),
            subtitle: L10n.text("Select all items in folder"),
            iconName: "checklist",
            category: .actions,
            shortcut: "⌘A",
            action: { nav.selectedItemIDs = Set(nav.items.map(\.url)) }
        ))

        items.append(CommandPaletteItem(
            id: "action-copy-path",
            title: L10n.text("Copy Current Path"),
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
            title: L10n.text("Calculate All Folder Sizes"),
            subtitle: L10n.text("Compute recursive directory sizes in background"),
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
            title: L10n.text("New Folder"),
            subtitle: L10n.text("Create a new folder in current directory"),
            iconName: "folder.badge.plus",
            category: .actions,
            shortcut: "⇧⌘N",
            action: { nav.requestedNewItemType = .folder }
        ))

        items.append(CommandPaletteItem(
            id: "action-new-file",
            title: L10n.text("New File"),
            subtitle: L10n.text("Create an empty file in current directory"),
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
            title: L10n.text("Home"),
            subtitle: home.path,
            iconName: "house",
            category: .navigation,
            shortcut: "⇧⌘H",
            action: { nav.navigateTo(home) }
        ))

        items.append(CommandPaletteItem(
            id: "place-desktop",
            title: L10n.text("Desktop"),
            subtitle: desktop.path,
            iconName: "desktopcomputer",
            category: .navigation,
            shortcut: "⌥⌘D",
            action: { nav.navigateTo(desktop) }
        ))

        items.append(CommandPaletteItem(
            id: "place-documents",
            title: L10n.text("Documents"),
            subtitle: documents.path,
            iconName: "doc.text",
            category: .navigation,
            shortcut: "⌥⌘O",
            action: { nav.navigateTo(documents) }
        ))

        items.append(CommandPaletteItem(
            id: "place-downloads",
            title: L10n.text("Downloads"),
            subtitle: downloads.path,
            iconName: "arrow.down.circle",
            category: .navigation,
            shortcut: "⌥⌘L",
            action: { nav.navigateTo(downloads) }
        ))

        items.append(CommandPaletteItem(
            id: "place-apps",
            title: L10n.text("Applications"),
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
                title: L10n.format("Restore Group: %@", L10n.literal(group.name)),
                subtitle: L10n.format("%@ (%@)", L10n.tabs(group.tabs.count), L10n.literal(group.tabs.map { URL(fileURLWithPath: $0.primaryPath).lastPathComponent }.joined(separator: ", "))),
                iconName: "square.stack.3d.up",
                category: .tabGroups,
                action: { TabGroupService.shared.restore(group: group, into: workspace, replace: false) }
            ))
        }

        return items
    }

    enum PathStatus: Sendable { case missing, file, directory }

    @concurrent static func pathStatus(for query: String) async -> PathStatus? {
        let path = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard path.hasPrefix("/") || path.hasPrefix("~"), !Task.isCancelled else { return nil }
        var directory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: (path as NSString).expandingTildeInPath, isDirectory: &directory)
        return exists ? (directory.boolValue ? .directory : .file) : .missing
    }

    /// Filters and ranks items without filesystem reads on the rendering path.
    func filter(query: String, for workspace: WorkspaceState, pathStatus: PathStatus? = nil) -> [CommandPaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Path navigation mode (starts with / or ~)
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            let expandedPath = (trimmed as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            let exists = pathStatus == .file || pathStatus == .directory
            let isDir = pathStatus == .directory

            let pathItem = CommandPaletteItem(
                id: "custom-path-navigate",
                title: L10n.format("Go to: %@", L10n.literal(trimmed)),
                subtitle: exists ? (isDir ? L10n.text("Directory exists") : L10n.text("File exists")) : L10n.format("Path: %@", L10n.literal(expandedPath)),
                iconName: isDir ? "folder" : "arrow.right.circle",
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

/// Owns one presented palette's result snapshot and its query-dependent disk work.
@MainActor @Observable
final class CommandPaletteResults {
    private(set) var items: [CommandPaletteItem] = []
    @ObservationIgnored private weak var workspace: WorkspaceState?
    @ObservationIgnored private var query = ""
    @ObservationIgnored private var pathStatus: CommandPaletteService.PathStatus?
    @ObservationIgnored private var pathTask: Task<Void, Never>?
    @ObservationIgnored private var observationID = UUID()
    @ObservationIgnored private var active = false

    init(workspace: WorkspaceState) { self.workspace = workspace }
    isolated deinit { pathTask?.cancel() }

    func start(query: String) {
        active = true
        update(query: query)
    }

    func stop() {
        active = false
        pathTask?.cancel()
        pathTask = nil
        observationID = UUID()
    }

    func update(query: String) {
        guard active else { return }
        self.query = query
        pathStatus = nil
        pathTask?.cancel()
        rebuild()
        pathTask = Task { [weak self] in
            let status = await CommandPaletteService.pathStatus(for: query)
            guard !Task.isCancelled, let self, self.active, self.query == query, let status else { return }
            self.pathStatus = status
            self.rebuild()
        }
    }

    private func rebuild() {
        guard active, let workspace else { return }
        let id = UUID()
        observationID = id
        items = withObservationTracking {
            CommandPaletteService.shared.filter(query: query, for: workspace, pathStatus: pathStatus)
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.active, self.observationID == id else { return }
                self.rebuild()
            }
        }
    }
}
