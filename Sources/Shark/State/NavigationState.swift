import Foundation
import Observation

public enum SortField: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case dateModified = "Date Modified"
    case size = "Size"
    case kind = "Kind"
    case permissions = "Permissions"

    public var id: String { rawValue }
}

public enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case grid = "Icons"
    case details = "List"
    case compact = "Columns"
    case gallery = "Gallery"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .details: return "list.bullet"
        case .compact: return "rectangle.split.3x1"
        case .gallery: return "macwindow"
        }
    }
}

@Observable
@MainActor
public final class NavigationState {
    public var currentURL: URL
    public private(set) var backStack: [URL] = []
    public private(set) var forwardStack: [URL] = []

    public var items: [FileItem] = []
    public var selectedItemIDs: Set<URL> = []
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public var showHiddenFiles: Bool = false {
        didSet {
            Task { await reloadCurrentDirectory() }
        }
    }

    public var isEditingPath: Bool = false
    public var pathInputText: String = ""

    public var filterText: String = ""
    public var isFilterBarVisible: Bool = false

    public var viewMode: ViewMode = .grid
    public var iconSize: CGFloat = 80.0

    public var sortField: SortField = .name
    public var sortAscending: Bool = true

    private let fileSystemService: FileSystemService

    public init(
        initialURL: URL? = nil,
        fileSystemService: FileSystemService = .shared
    ) {
        let initial = initialURL ?? FileManager.default.homeDirectoryForCurrentUser
        self.currentURL = initial.standardizedFileURL
        self.fileSystemService = fileSystemService
        self.pathInputText = self.currentURL.path
    }

    public var canGoBack: Bool {
        !backStack.isEmpty
    }

    public var canGoForward: Bool {
        !forwardStack.isEmpty
    }

    public var canGoUp: Bool {
        currentURL.path != "/" && currentURL.deletingLastPathComponent().path != currentURL.path
    }

    public func navigateTo(_ url: URL) {
        let standardized = url.standardizedFileURL
        guard standardized != currentURL else { return }

        backStack.append(currentURL)
        forwardStack.removeAll()
        currentURL = standardized
        pathInputText = standardized.path
        selectedItemIDs.removeAll()

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goBack() {
        guard canGoBack, let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
        pathInputText = previous.path
        selectedItemIDs.removeAll()

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goForward() {
        guard canGoForward, let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
        pathInputText = next.path
        selectedItemIDs.removeAll()

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goUp() {
        guard canGoUp else { return }
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        navigateTo(parent)
    }

    public func reloadCurrentDirectory() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedItems = try await fileSystemService.contentsOfDirectory(
                at: currentURL,
                showHidden: showHiddenFiles
            )
            self.items = fetchedItems
        } catch {
            self.errorMessage = error.localizedDescription
            self.items = []
        }
        self.isLoading = false
    }

    public func commitPathInput() {
        isEditingPath = false
        if let resolved = fileSystemService.resolvePath(pathInputText) {
            navigateTo(resolved)
        } else {
            errorMessage = "Path not found: \(pathInputText)"
        }
    }

    public var filteredAndSortedItems: [FileItem] {
        var result = items

        if !filterText.isEmpty {
            let query = filterText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        result.sort { itemA, itemB in
            if itemA.isDirectory != itemB.isDirectory {
                return itemA.isDirectory
            }

            switch sortField {
            case .name:
                let comp = itemA.name.localizedStandardCompare(itemB.name)
                return sortAscending ? comp == .orderedAscending : comp == .orderedDescending
            case .dateModified:
                return sortAscending
                    ? itemA.dateModified < itemB.dateModified
                    : itemA.dateModified > itemB.dateModified
            case .size:
                return sortAscending
                    ? itemA.fileSize < itemB.fileSize
                    : itemA.fileSize > itemB.fileSize
            case .kind:
                let comp = itemA.kindDescription.localizedStandardCompare(itemB.kindDescription)
                return sortAscending ? comp == .orderedAscending : comp == .orderedDescending
            case .permissions:
                let comp = itemA.permissionsString.localizedStandardCompare(itemB.permissionsString)
                return sortAscending ? comp == .orderedAscending : comp == .orderedDescending
            }
        }

        return result
    }
}
