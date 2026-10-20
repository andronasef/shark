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

    // Explorer Ergonomics additions
    public var renamingItemURL: URL? = nil
    public var isBottomPathBarVisible: Bool = true
    public var activeOperationProgress: Double? = nil
    public var activeOperationTitle: String? = nil

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

    public var selectedItems: [FileItem] {
        items.filter { selectedItemIDs.contains($0.url) }
    }

    public var selectedTotalSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.fileSize }
    }

    public func navigateTo(_ url: URL) {
        let standardized = url.standardizedFileURL
        guard standardized != currentURL else { return }

        backStack.append(currentURL)
        forwardStack.removeAll()
        currentURL = standardized
        pathInputText = standardized.path
        selectedItemIDs.removeAll()
        renamingItemURL = nil

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
        renamingItemURL = nil

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
        renamingItemURL = nil

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

    // MARK: - Explorer Operations

    public func isCut(_ item: FileItem) -> Bool {
        FileClipboardService.shared.isCut(item.url)
    }

    public func cutSelected() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        FileClipboardService.shared.cut(urls)
    }

    public func copySelected() {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        FileClipboardService.shared.copy(urls)
    }

    public func paste() async {
        guard let (urls, mode) = FileClipboardService.shared.getPasteableURLs(), !urls.isEmpty else { return }
        let targetDir = currentURL

        do {
            if mode == .cut {
                var pairs: [(source: URL, destination: URL)] = []
                for url in urls {
                    let dest = targetDir.appendingPathComponent(url.lastPathComponent)
                    if FileManager.default.fileExists(atPath: dest.path) {
                        try? FileManager.default.removeItem(at: dest)
                    }
                    try FileManager.default.moveItem(at: url, to: dest)
                    pairs.append((source: url, destination: dest))
                }
                FileUndoService.shared.record(.move(pairs: pairs))
                FileClipboardService.shared.clear()
            } else {
                try await FileOperationsService.shared.copy(items: urls, to: targetDir)
                let created = urls.map { targetDir.appendingPathComponent($0.lastPathComponent) }
                FileUndoService.shared.record(.copy(createdURLs: created, originalSources: urls, destinationDir: targetDir))
            }
            await reloadCurrentDirectory()
        } catch {
            self.errorMessage = "Paste failed: \(error.localizedDescription)"
        }
    }

    public func undo() async {
        guard FileUndoService.shared.canUndo else { return }
        do {
            try await FileUndoService.shared.undo()
            await reloadCurrentDirectory()
        } catch {
            self.errorMessage = "Undo failed: \(error.localizedDescription)"
        }
    }

    public func redo() async {
        guard FileUndoService.shared.canRedo else { return }
        do {
            try await FileUndoService.shared.redo()
            await reloadCurrentDirectory()
        } catch {
            self.errorMessage = "Redo failed: \(error.localizedDescription)"
        }
    }

    public func startRenaming(url: URL) {
        renamingItemURL = url
    }

    public func commitRename(url: URL, newName: String) async {
        guard !newName.isEmpty && newName != url.lastPathComponent else {
            renamingItemURL = nil
            return
        }
        do {
            let newURL = try await FileOperationsService.shared.rename(item: url, to: newName)
            FileUndoService.shared.record(.rename(original: url, current: newURL))
            renamingItemURL = nil
            await reloadCurrentDirectory()
            selectedItemIDs = [newURL]
        } catch {
            self.errorMessage = "Rename failed: \(error.localizedDescription)"
            renamingItemURL = nil
        }
    }

    public func cancelRenaming() {
        renamingItemURL = nil
    }

    public func compressSelected() async {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        activeOperationTitle = "Compressing..."
        activeOperationProgress = 0.5
        do {
            let archiveURL = try await FileOperationsService.shared.compress(items: urls)
            activeOperationTitle = nil
            activeOperationProgress = nil
            await reloadCurrentDirectory()
            selectedItemIDs = [archiveURL]
        } catch {
            activeOperationTitle = nil
            activeOperationProgress = nil
            self.errorMessage = "Compress failed: \(error.localizedDescription)"
        }
    }

    public func trashSelected() async {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        do {
            try await FileOperationsService.shared.trash(items: urls)
            await reloadCurrentDirectory()
            selectedItemIDs.removeAll()
        } catch {
            self.errorMessage = "Trash failed: \(error.localizedDescription)"
        }
    }
}
