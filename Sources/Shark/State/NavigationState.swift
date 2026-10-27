import AppKit
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
        didSet { refreshSortedItems() }
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
            guard oldValue != showHiddenFiles else { return }
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
        didSet { if oldValue != sortField && !updatingSort { refreshSortedItems() } }
    }
    public var sortAscending: Bool = true {
        didSet { if oldValue != sortAscending && !updatingSort { refreshSortedItems() } }
    }
    public var gridColumnCount: Int = 1

    // Explorer Ergonomics additions
    public var renamingItemURL: URL? = nil
    public var requestedNewItemType: NewItemType? = nil
    public var isBottomPathBarVisible: Bool = true
    public var activeOperationProgress: Double? = nil
    public var activeOperationTitle: String? = nil
    /// Stops the running operation shown in the status bar; nil when it can't be cancelled.
    public private(set) var cancelActiveOperation: (() -> Void)? = nil

    private let fileSystemService: FileSystemService
    private var lastRecordedVisit: URL?
    @ObservationIgnored private var sortedItems: [FileItem] = []
    @ObservationIgnored private var visibleIndices: [URL: Int] = [:]
    @ObservationIgnored private var updatingSort = false
    @ObservationIgnored private var reloadTask: Task<[FileItem], any Error>?
    @ObservationIgnored private var reloadID = UUID()
    @ObservationIgnored private var scheduledReload: Task<Void, Never>?
    @ObservationIgnored private let readDirectory: @Sendable (URL, Bool) async throws -> [FileItem]

    public init(
        initialURL: URL? = nil,
        fileSystemService: FileSystemService = .shared
    ) {
        let initial = initialURL ?? FileManager.default.homeDirectoryForCurrentUser
        self.currentURL = initial.standardizedFileURL
        self.fileSystemService = fileSystemService
        self.readDirectory = { url, hidden in
            try await fileSystemService.contentsOfDirectory(at: url, showHidden: hidden)
        }
        self.pathInputText = self.currentURL.path
    }

    init(initialURL: URL, readDirectory: @escaping @Sendable (URL, Bool) async throws -> [FileItem]) {
        currentURL = initialURL.standardizedFileURL
        fileSystemService = .shared
        self.readDirectory = readDirectory
        pathInputText = currentURL.path
    }

    public func setSort(field: SortField, ascending: Bool) {
        guard field != sortField || ascending != sortAscending else { return }
        updatingSort = true
        sortField = field
        sortAscending = ascending
        updatingSort = false
        refreshSortedItems()
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
        if selectedItemIDs.count == filteredAndSortedItems.count,
           selectedItemIDs.allSatisfy({ visibleIndices[$0] != nil }) { return filteredAndSortedItems }
        return selectedItemIDs.compactMap { visibleIndices[$0] }.sorted().map { filteredAndSortedItems[$0] }
    }

    public var selectedTotalSize: Int64 {
        selectedItemIDs.reduce(0) { total, id in
            total + (visibleIndices[id].map { filteredAndSortedItems[$0].fileSize } ?? 0)
        }
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
    }

    public func goBack() {
        guard canGoBack, let previous = backStack.popLast() else { return }
        forwardStack.append(currentURL)
        currentURL = previous
        pathInputText = previous.path
        selectedItemIDs.removeAll()
        renamingItemURL = nil
    }

    public func goForward() {
        guard canGoForward, let next = forwardStack.popLast() else { return }
        backStack.append(currentURL)
        currentURL = next
        pathInputText = next.path
        selectedItemIDs.removeAll()
        renamingItemURL = nil
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

    /// Coalesces filesystem event bursts; explicit reloads still take effect immediately.
    public func requestReload() {
        scheduledReload?.cancel()
        scheduledReload = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
            guard !Task.isCancelled, let self else { return }
            self.scheduledReload = nil
            await self.reloadCurrentDirectory()
        }
    }

    public func reloadCurrentDirectory() async {
        scheduledReload?.cancel()
        scheduledReload = nil
        reloadTask?.cancel()
        let id = UUID()
        reloadID = id
        isLoading = true
        errorMessage = nil
        isPermissionError = false
        let url = currentURL
        let hidden = showHiddenFiles
        SecurityScopedBookmarkManager.shared.ensureAccess(to: url)
        let reader = readDirectory
        let task = Task { try await reader(url, hidden) }
        reloadTask = task
        defer {
            if reloadID == id { isLoading = false; reloadTask = nil }
        }
        do {
            let fetchedItems = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: { task.cancel() }
            guard reloadID == id, url == currentURL, !Task.isCancelled, !task.isCancelled else { return }
            items = fetchedItems
            if lastRecordedVisit != url {
                lastRecordedVisit = url
                RecentFoldersService.shared.recordVisit(to: url)
            }
        } catch {
            guard reloadID == id, url == currentURL, !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = error.localizedDescription
            let ns = error as NSError
            let underlying = ns.userInfo[NSUnderlyingErrorKey] as? NSError
            isPermissionError = ns.code == NSFileReadNoPermissionError
                || [ns, underlying].contains { error in
                    guard let error else { return false }
                    return error.domain == NSPOSIXErrorDomain && [EPERM, EACCES].contains(Int32(error.code))
                }
            items = []
        }
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
            errorMessage = L10n.format("Path not found: %@", L10n.literal(pathInputText))
        }
    }

    private func refreshSortedItems() {
        var result = items
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

        sortedItems = result
        refreshVisibleItems()
    }

    private func refreshVisibleItems() {
        let result = filterText.isEmpty ? sortedItems : sortedItems.filter { $0.name.localizedStandardContains(filterText) }
        filteredAndSortedItems = result
        var indices: [URL: Int] = [:]
        indices.reserveCapacity(result.count)
        for (index, item) in result.enumerated() { indices[item.id] = index }
        visibleIndices = indices

        // Never keep hidden or vanished items selected: a later Trash or Cut would act on
        // files the user can't see.
        if !selectedItemIDs.allSatisfy({ indices[$0] != nil }) {
            selectedItemIDs = selectedItemIDs.filter { indices[$0] != nil }
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

    public func paste(into destination: URL? = nil) async {
        guard let (urls, mode) = FileClipboardService.shared.getPasteableURLs(), !urls.isEmpty else { return }
        let targetDir = destination ?? currentURL

        do {
            if mode == .cut {
                let pairs = try await FileOperationsService.shared.move(items: urls, to: targetDir)
                if !pairs.isEmpty { FileUndoService.shared.record(.move(pairs: pairs)) }
                FileClipboardService.shared.clear()
            } else {
                let created = try await FileOperationsService.shared.copy(items: urls, to: targetDir)
                FileUndoService.shared.record(.create(urls: created, name: L10n.text("Copy")))
            }
        } catch {
            if let partial = error as? PartialMoveError { FileUndoService.shared.record(.move(pairs: partial.remainingMoves)) }
            operationError = L10n.format("Paste failed: %@", error.localizedDescription)
        }
        await reloadCurrentDirectory()
    }

    /// Drops `urls` into `directory`. Like Finder, a drop moves within a volume and copies across
    /// volumes; ⌥ forces a copy and ⌘ forces a move.
    public func drop(_ urls: [URL], into directory: URL, modifiers: NSEvent.ModifierFlags) async {
        let urls = FileDragSelection.normalized(urls)
        guard !urls.isEmpty else { return }
        let crossesVolume = urls.contains { !FileOperationsService.isSameVolume($0, directory) }
        let copies = modifiers.contains(.option) || (crossesVolume && !modifiers.contains(.command))
        do {
            if copies {
                let created = try await FileOperationsService.shared.copy(items: urls, to: directory)
                FileUndoService.shared.record(.create(urls: created, name: L10n.text("Copy")))
            } else {
                let pairs = try await FileOperationsService.shared.move(items: urls, to: directory)
                if !pairs.isEmpty { FileUndoService.shared.record(.move(pairs: pairs)) }
            }
        } catch {
            if let partial = error as? PartialMoveError { FileUndoService.shared.record(.move(pairs: partial.remainingMoves)) }
            operationError = L10n.format("%@ failed: %@", L10n.text(copies ? "Copy" : "Move"), error.localizedDescription)
        }
        await reloadCurrentDirectory()
    }

    public func duplicateSelected() async {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        do {
            let created = try await FileOperationsService.shared.duplicate(items: urls)
            FileUndoService.shared.record(.create(urls: created, name: L10n.text("Duplicate")))
            await reloadCurrentDirectory()
            selectedItemIDs = Set(created.map(\.standardizedFileURL))
        } catch {
            operationError = L10n.format("Duplicate failed: %@", error.localizedDescription)
            await reloadCurrentDirectory()
        }
    }

    public func undo() async {
        guard FileUndoService.shared.canUndo else { return }
        do {
            try await FileUndoService.shared.undo()
        } catch {
            operationError = L10n.format("Undo failed: %@", error.localizedDescription)
        }
        await reloadCurrentDirectory()
    }

    public func redo() async {
        guard FileUndoService.shared.canRedo else { return }
        do {
            try await FileUndoService.shared.redo()
        } catch {
            operationError = L10n.format("Redo failed: %@", error.localizedDescription)
        }
        await reloadCurrentDirectory()
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
            selectionAnchorID = newURL
        } catch {
            self.operationError = L10n.format("Rename failed: %@", error.localizedDescription)
            renamingItemURL = nil
        }
    }

    public func cancelRenaming() {
        renamingItemURL = nil
    }

    public func compressSelected() async {
        guard cancelActiveOperation == nil else { return }
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        activeOperationTitle = L10n.text("Compressing...")
        activeOperationProgress = 0.5
        let task = Task { try await FileOperationsService.shared.compress(items: urls) }
        cancelActiveOperation = { task.cancel() }
        defer {
            activeOperationTitle = nil
            activeOperationProgress = nil
            cancelActiveOperation = nil
        }
        do {
            let archiveURL = try await task.value
            FileUndoService.shared.record(.create(urls: [archiveURL], name: L10n.text("Compress")))
            await reloadCurrentDirectory()
            selectedItemIDs = [archiveURL]
        } catch is CancellationError {
            await reloadCurrentDirectory()
        } catch {
            self.operationError = L10n.format("Compress failed: %@", error.localizedDescription)
        }
    }

    public func trashSelected() async {
        let urls = selectedItems.map(\.url)
        guard !urls.isEmpty else { return }
        do {
            let restorations = try await FileOperationsService.shared.trash(items: urls)
            FileUndoService.shared.record(.trash(restorations: restorations))
            selectedItemIDs.removeAll()
        } catch {
            self.operationError = L10n.format("Move to Trash failed: %@", error.localizedDescription)
        }
        await reloadCurrentDirectory()
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
        } else if shift, let from = focusIndex(),
                  let to = filteredAndSortedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItemIDs.formUnion(filteredAndSortedItems[min(from, to)...max(from, to)].map(\.id))
        } else {
            selectOnly(item)
        }
    }

    /// The anchor when it is still selected, otherwise the first selected item in display order.
    private func focusIndex() -> Int? {
        if let anchor = selectionAnchorID, selectedItemIDs.contains(anchor), let index = visibleIndices[anchor] {
            return index
        }
        return selectedItemIDs.compactMap { visibleIndices[$0] }.min()
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
        guard let current = focusIndex() else {
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
}
