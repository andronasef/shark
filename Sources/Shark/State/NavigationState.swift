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

    public var items: [FileItem] = [] {
        didSet { refreshVisibleItems() }
    }
    /// `items` after the filter and sort, recomputed only when one of them changes.
    public private(set) var filteredAndSortedItems: [FileItem] = []
    public var selectedItemIDs: Set<URL> = []
    /// The item keyboard navigation and Shift-click ranges start from.
    public var selectionAnchorID: URL? = nil
    public var isLoading: Bool = false
    /// Set when the folder itself could not be listed; replaces the folder contents with an error page.
    public var errorMessage: String? = nil
    /// Set when a file operation (paste, drop, rename, trash, undo…) fails; shown as an alert.
    public var operationError: String? = nil
    /// True when the last directory load failed because macOS privacy protection (TCC) denied access.
    public var isPermissionError = false

    public var showHiddenFiles: Bool = false {
        didSet {
            Task { await reloadCurrentDirectory() }
        }
    }

    public var isEditingPath: Bool = false
    public var pathInputText: String = ""

    public var filterText: String = "" {
        didSet { refreshVisibleItems() }
    }

    public var viewMode: ViewMode = .grid
    public var iconSize: CGFloat = 80.0

    public var sortField: SortField = .name {
        didSet { refreshVisibleItems() }
    }
    public var sortAscending: Bool = true {
        didSet { refreshVisibleItems() }
    }
    public var gridColumnCount: Int = 1

    // Explorer Ergonomics additions
    public var renamingItemURL: URL? = nil
    public var requestedNewItemType: NewItemType? = nil
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

    /// Selected items in display order.
    public var selectedItems: [FileItem] {
        filteredAndSortedItems.filter { selectedItemIDs.contains($0.url) }
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

    public func zoomIn(by amount: CGFloat = 16.0) {
        iconSize = min(192.0, iconSize + amount)
    }

    public func zoomOut(by amount: CGFloat = 16.0) {
        iconSize = max(48.0, iconSize - amount)
    }

    public func adjustZoom(delta: CGFloat) {
        // Normalize discrete mouse wheel vs continuous trackpad gestures
        let step: CGFloat
        if abs(delta) > 5.0 {
            // Trackpad swipe or large wheel flick
            step = (delta > 0 ? 1 : -1) * 8.0
        } else {
            step = (delta > 0 ? 1 : -1) * 4.0
        }
        let newSize = max(48.0, min(192.0, iconSize + step))
        iconSize = newSize
    }

    public func resetZoom() {
        iconSize = 80.0
    }

    public func reloadCurrentDirectory() async {
        isLoading = true
        errorMessage = nil
        isPermissionError = false

        SecurityScopedBookmarkManager.shared.ensureAccess(to: currentURL)

        do {
            let fetchedItems = try await fileSystemService.contentsOfDirectory(
                at: currentURL,
                showHidden: showHiddenFiles
            )
            self.items = fetchedItems
            RecentFoldersService.shared.recordVisit(to: self.currentURL)
        } catch {
            self.errorMessage = error.localizedDescription
            let ns = error as NSError
            let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError
            self.isPermissionError = ns.code == NSFileReadNoPermissionError
                || [ns, underlying].contains { $0?.domain == NSPOSIXErrorDomain && [EPERM, EACCES].contains(Int32($0!.code)) }
            self.items = []
        }
        self.isLoading = false
    }

    /// Requests user authorization to browse the current directory via NSOpenPanel.
    /// Under App Sandbox, this allows the user to grant read-write access and persists a security-scoped bookmark.
    public func requestFolderAccess() async {
        let granted = await SecurityScopedBookmarkManager.shared.promptUserForAccess(to: currentURL)
        if granted {
            await reloadCurrentDirectory()
        }
    }

    public func commitPathInput() {
        isEditingPath = false
        if let resolved = fileSystemService.resolvePath(pathInputText) {
            navigateTo(resolved)
        } else {
            errorMessage = "Path not found: \(pathInputText)"
        }
    }

    private func refreshVisibleItems() {
        var result = items

        if !filterText.isEmpty {
            result = result.filter { $0.name.localizedStandardContains(filterText) }
        }

        let field = sortField
        let ascending = sortAscending
        result.sort { itemA, itemB in
            if itemA.isDirectory != itemB.isDirectory {
                return itemA.isDirectory
            }

            switch field {
            case .name:
                let comp = itemA.name.localizedStandardCompare(itemB.name)
                return ascending ? comp == .orderedAscending : comp == .orderedDescending
            case .dateModified:
                return ascending
                    ? itemA.dateModified < itemB.dateModified
                    : itemA.dateModified > itemB.dateModified
            case .size:
                return ascending
                    ? itemA.fileSize < itemB.fileSize
                    : itemA.fileSize > itemB.fileSize
            case .kind:
                let comp = itemA.kindDescription.localizedStandardCompare(itemB.kindDescription)
                return ascending ? comp == .orderedAscending : comp == .orderedDescending
            case .permissions:
                let comp = itemA.permissionsString.localizedStandardCompare(itemB.permissionsString)
                return ascending ? comp == .orderedAscending : comp == .orderedDescending
            }
        }

        filteredAndSortedItems = result

        // Never keep hidden or vanished items selected: a later Trash or Cut would act on
        // files the user can't see.
        let visibleIDs = Set(result.map(\.id))
        if !selectedItemIDs.isSubset(of: visibleIDs) {
            selectedItemIDs.formIntersection(visibleIDs)
        }
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

    public func selectAll() {
        selectedItemIDs = Set(filteredAndSortedItems.map(\.id))
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

    // MARK: - Selection (Finder style)

    /// Applies a click: ⌘ toggles the item, ⇧ extends from the anchor, a plain click selects only it.
    public func click(_ item: FileItem, command: Bool, shift: Bool) {
        if command {
            if selectedItemIDs.contains(item.id) {
                selectedItemIDs.remove(item.id)
            } else {
                selectedItemIDs.insert(item.id)
            }
            selectionAnchorID = item.id
        } else if shift, let from = focusIndex(in: filteredAndSortedItems),
                  let to = filteredAndSortedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItemIDs.formUnion(filteredAndSortedItems[min(from, to)...max(from, to)].map(\.id))
        } else {
            selectOnly(item)
        }
    }

    /// The anchor when it is still selected, otherwise the first selected item in display order.
    private func focusIndex(in items: [FileItem]) -> Int? {
        if let anchor = selectionAnchorID, selectedItemIDs.contains(anchor),
           let index = items.firstIndex(where: { $0.id == anchor }) {
            return index
        }
        return items.firstIndex { selectedItemIDs.contains($0.id) }
    }

    private func selectOnly(_ item: FileItem) {
        selectedItemIDs = [item.id]
        selectionAnchorID = item.id
    }

    /// Moves the keyboard selection by `offset` items; with no selection, selects the first item.
    /// Out-of-range moves stay put unless `clamp` is set.
    private func moveSelection(by offset: Int, clamp: Bool) {
        let items = filteredAndSortedItems
        guard !items.isEmpty else { return }
        guard let current = focusIndex(in: items) else {
            selectOnly(items[0])
            return
        }
        let target = current + offset
        if items.indices.contains(target) {
            selectOnly(items[target])
        } else if clamp {
            selectOnly(items[max(0, min(items.count - 1, target))])
        }
    }

    public func selectPreviousItem() {
        moveSelection(by: -1, clamp: true)
    }

    public func selectNextItem() {
        moveSelection(by: 1, clamp: true)
    }

    public func selectAboveItem(approximateColumns: Int? = nil) {
        moveSelection(by: -max(1, approximateColumns ?? gridColumnCount), clamp: false)
    }

    public func selectBelowItem(approximateColumns: Int? = nil) {
        moveSelection(by: max(1, approximateColumns ?? gridColumnCount), clamp: false)
    }

    public func selectFirstItem() {
        if let first = filteredAndSortedItems.first { selectOnly(first) }
    }

    public func selectLastItem() {
        if let last = filteredAndSortedItems.last { selectOnly(last) }
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
