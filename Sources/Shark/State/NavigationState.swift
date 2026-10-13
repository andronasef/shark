import Foundation
import SwiftUI
import Observation

public enum SortField: String, CaseIterable, Identifiable, Sendable {
    case name = "Name"
    case size = "Size"
    case dateModified = "Date Modified"
    case kind = "Kind"
    case permissions = "Permissions"

    public var id: String { rawValue }
}

public enum ViewMode: String, CaseIterable, Identifiable, Sendable {
    case details = "Details"
    case grid = "Icons"
    case compact = "Compact"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .details: return "list.bullet"
        case .grid: return "square.grid.2x2"
        case .compact: return "list.dash"
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

    public var viewMode: ViewMode = .details
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
        currentURL.path != "/"
    }

    public var filteredAndSortedItems: [FileItem] {
        var result = items

        // Filter
        if !filterText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = filterText.lowercased()
            result = result.filter { item in
                item.name.lowercased().contains(query) ||
                item.kindDescription.lowercased().contains(query)
            }
        }

        // Sort: Always keep directories first (Dolphin style) unless specified otherwise
        result.sort { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }

            let comparison: ComparisonResult
            switch sortField {
            case .name:
                comparison = a.name.localizedStandardCompare(b.name)
            case .size:
                comparison = a.fileSize < b.fileSize ? .orderedAscending : (a.fileSize > b.fileSize ? .orderedDescending : .orderedSame)
            case .dateModified:
                comparison = a.dateModified.compare(b.dateModified)
            case .kind:
                comparison = a.kindDescription.localizedStandardCompare(b.kindDescription)
            case .permissions:
                comparison = a.permissionsString.compare(b.permissionsString)
            }

            return sortAscending ? (comparison == .orderedAscending) : (comparison == .orderedDescending)
        }

        return result
    }

    public func navigateTo(_ url: URL, recordHistory: Bool = true) {
        let normalized = url.standardizedFileURL
        guard normalized != currentURL else { return }

        if recordHistory {
            backStack.append(currentURL)
            forwardStack.removeAll()
        }

        currentURL = normalized
        pathInputText = normalized.path
        selectedItemIDs.removeAll()
        filterText = ""

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goBack() {
        guard let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
        pathInputText = previous.path
        selectedItemIDs.removeAll()
        filterText = ""

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goForward() {
        guard let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
        pathInputText = next.path
        selectedItemIDs.removeAll()
        filterText = ""

        Task {
            await reloadCurrentDirectory()
        }
    }

    public func goUp() {
        guard canGoUp else { return }
        let parent = currentURL.deletingLastPathComponent().standardizedFileURL
        navigateTo(parent)
    }

    public func reloadCurrentDirectory() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await fileSystemService.contentsOfDirectory(at: currentURL, showHidden: showHiddenFiles)
            self.items = loaded
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.items = []
            self.isLoading = false
        }
    }

    public func commitPathInput() {
        let input = pathInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        isEditingPath = false

        guard !input.isEmpty else {
            pathInputText = currentURL.path
            return
        }

        if let resolved = fileSystemService.resolvePath(input) {
            navigateTo(resolved)
        } else {
            pathInputText = currentURL.path
        }
    }
}
