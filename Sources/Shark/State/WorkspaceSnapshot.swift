import Foundation

public func existingAncestor(_ url: URL) -> URL {
    var u = url.standardizedFileURL
    var isDir: ObjCBool = false
    while u.path != "/" {
        if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue {
            return u
        }
        u.deleteLastPathComponent()
    }
    return FileManager.default.homeDirectoryForCurrentUser
}

public struct PaneSnapshot: Codable, Equatable, Sendable {
    public var url: URL
    public var viewMode: String
    public var sortField: String
    public var sortAscending: Bool
    public var showHidden: Bool
    public var iconSize: CGFloat
    public var bookmarkData: Data?

    public init(
        url: URL,
        viewMode: String,
        sortField: String,
        sortAscending: Bool,
        showHidden: Bool,
        iconSize: CGFloat,
        bookmarkData: Data? = nil
    ) {
        self.url = url
        self.viewMode = viewMode
        self.sortField = sortField
        self.sortAscending = sortAscending
        self.showHidden = showHidden
        self.iconSize = iconSize
        self.bookmarkData = bookmarkData
    }

    public var decodedViewMode: ViewMode {
        ViewMode.allCases.first { "\($0)" == viewMode } ?? .grid
    }

    public var decodedSortField: SortField {
        SortField.allCases.first { "\($0)" == sortField } ?? .name
    }
}

public struct TabSnapshot: Codable, Equatable, Sendable {
    public var id: UUID
    public var isPinned: Bool
    public var isLocked: Bool
    public var color: TabColor?
    public var isSplit: Bool
    public var activePane: PaneIdentifier
    public var primary: PaneSnapshot
    public var secondary: PaneSnapshot

    public init(
        id: UUID,
        isPinned: Bool,
        isLocked: Bool,
        color: TabColor?,
        isSplit: Bool,
        activePane: PaneIdentifier,
        primary: PaneSnapshot,
        secondary: PaneSnapshot
    ) {
        self.id = id
        self.isPinned = isPinned
        self.isLocked = isLocked
        self.color = color
        self.isSplit = isSplit
        self.activePane = activePane
        self.primary = primary
        self.secondary = secondary
    }
}

public struct ClosedTab: Codable, Equatable, Sendable {
    public var tab: TabSnapshot
    public var index: Int

    public init(tab: TabSnapshot, index: Int) {
        self.tab = tab
        self.index = index
    }
}

public struct WorkspaceSnapshot: Codable, Equatable, Sendable {
    public var tabs: [TabSnapshot]
    public var activeTabID: UUID?
    public var closedTabs: [ClosedTab]

    public init(tabs: [TabSnapshot], activeTabID: UUID?, closedTabs: [ClosedTab] = []) {
        self.tabs = tabs
        self.activeTabID = activeTabID
        self.closedTabs = closedTabs
    }
}
