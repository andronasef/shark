import Foundation
import Observation

/// How the sidebar presents places. The raw values are persisted.
public enum SidebarStyle: String, CaseIterable, Identifiable, Sendable {
    case places, tree
    public static let storageKey = "sidebarStyle"
    public var id: String { rawValue }
    public static func preference(_ value: String?) -> Self { value.flatMap(Self.init(rawValue:)) ?? .places }
    var displayName: String { self == .places ? L10n.text("Places") : L10n.text("Folder Tree") }
}

struct FolderTreeRoot: Equatable, Sendable {
    let url: URL
    let name: String
    let icon: String
}

/// Pure folder-listing logic behind the sidebar's Folder Tree, kept apart from the view for testing.
enum FolderTree {
    /// Subfolders only, sorted like Finder. Packages are files, hidden items follow `showHidden`,
    /// and a symlink counts as a folder only when it points at one.
    nonisolated static func childFolders(of url: URL, showHidden: Bool) -> [URL] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey]
        let options: FileManager.DirectoryEnumerationOptions = showHidden ? [] : [.skipsHiddenFiles]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options) else { return [] }
        let keySet = Set(keys)
        var folders: [URL] = []
        for child in urls {
            guard !Task.isCancelled else { return [] }
            let values = try? child.resourceValues(forKeys: keySet)
            if values?.isPackage == true { continue }
            let directory = values?.isSymbolicLink == true
                ? (try? child.resolvingSymlinksInPath().resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                : values?.isDirectory == true
            if directory { folders.append(child) }
        }
        return folders.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    nonisolated static func key(_ url: URL) -> String { url.standardizedFileURL.path }

    /// The deepest root that contains `target` (Home wins over `/` for a folder inside Home).
    nonisolated static func root(containing target: URL, among roots: [URL]) -> URL? {
        let path = key(target)
        return roots.filter { root in
            let r = key(root)
            return r == "/" || path == r || path.hasPrefix(r + "/")
        }.max { key($0).count < key($1).count }
    }

    /// Folders to expand so `target` is visible: `root` down to `target`'s parent.
    nonisolated static func ancestors(of target: URL, below root: URL) -> [URL] {
        let t = target.standardizedFileURL.pathComponents
        let r = root.standardizedFileURL.pathComponents
        guard t.starts(with: r), t.count > r.count else { return [] }
        return (r.count...(t.count - 1)).map { count in
            URL(fileURLWithPath: NSString.path(withComponents: Array(t.prefix(count))), isDirectory: true)
        }
    }
}

/// Which tree nodes are open and what is known about their children. Directory reads run off
/// the main actor; a folder's children load when it is first expanded.
@MainActor @Observable
final class FolderTreeModel {
    struct Row: Identifiable, Equatable {
        let url: URL
        let name: String
        let icon: String
        let depth: Int
        let isExpanded: Bool
        let canExpand: Bool
        let id: String
    }

    static let defaultsKey = "folderTree.expanded"
    private(set) var expanded: Set<String> { didSet { revision &+= 1 } }
    private(set) var children: [String: [URL]] = [:] { didSet { revision &+= 1 } }
    private var revision = 0
    @ObservationIgnored private var cachedRevision = -1
    @ObservationIgnored private var cachedRoots: [FolderTreeRoot] = []
    @ObservationIgnored private var cachedRows: [Row] = []
    @ObservationIgnored private var loads: [String: (id: UUID, task: Task<[URL], Never>)] = [:]
    @ObservationIgnored private var listingHidden: Bool?
    @ObservationIgnored private var visibilityGeneration = UUID()
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        expanded = Set(defaults.stringArray(forKey: Self.defaultsKey) ?? [])
    }

    func isExpanded(_ url: URL) -> Bool { expanded.contains(FolderTree.key(url)) }

    func toggle(_ url: URL, showHidden: Bool) async {
        if isExpanded(url) { collapse(url) } else { await expand(url, showHidden: showHidden) }
    }

    func expand(_ url: URL, showHidden: Bool) async {
        guard listingHidden == nil || listingHidden == showHidden else { return }
        let generation = visibilityGeneration
        let key = FolderTree.key(url)
        expanded.insert(key)
        persist()
        await load(url, showHidden: showHidden)
        guard generation == visibilityGeneration else { return }
        await loadRememberedDescendants(below: url, showHidden: showHidden)
    }

    private func loadRememberedDescendants(below root: URL, showHidden: Bool) async {
        let generation = visibilityGeneration
        var pending = children[FolderTree.key(root)] ?? []
        var index = 0
        var visited: Set<String> = []
        while index < pending.count {
            guard !Task.isCancelled, isExpanded(root), generation == visibilityGeneration else { return }
            let url = pending[index]
            index += 1
            let key = FolderTree.key(url)
            guard expanded.contains(key), visited.insert(key).inserted else { continue }
            if children[key] == nil { await load(url, showHidden: showHidden) }
            pending.append(contentsOf: children[key] ?? [])
        }
    }

    func collapse(_ url: URL) {
        expanded.remove(FolderTree.key(url))
        persist()
    }

    /// Newer requests own publication; cancellation also stops enumeration cooperatively.
    func load(_ url: URL, showHidden: Bool) async {
        guard listingHidden == nil || listingHidden == showHidden else { return }
        let key = FolderTree.key(url)
        loads[key]?.task.cancel()
        let id = UUID()
        let task = Task { await Self.list(url, showHidden: showHidden) }
        loads[key] = (id, task)
        let listing = await withTaskCancellationHandler { await task.value } onCancel: { task.cancel() }
        guard loads[key]?.id == id else { return }
        loads.removeValue(forKey: key)
        guard !Task.isCancelled, !task.isCancelled else { return }
        children[key] = listing
    }

    @concurrent private static func list(_ url: URL, showHidden: Bool) async -> [URL] {
        FolderTree.childFolders(of: url, showHidden: showHidden)
    }

    func reloadExpanded(showHidden: Bool) async {
        // Invalidate hidden descendants too, without reading them while collapsed.
        listingHidden = showHidden
        let generation = UUID()
        visibilityGeneration = generation
        for load in loads.values { load.task.cancel() }
        loads.removeAll()
        children.removeAll()
        // Roots remembered by rows(for:) determine which expansion paths are reachable.
        let roots = cachedRoots
        var pending = roots.map(\.url)
        var index = 0
        var visited: Set<String> = []
        while index < pending.count {
            guard !Task.isCancelled, visibilityGeneration == generation else { return }
            let url = pending[index]
            index += 1
            let key = FolderTree.key(url)
            guard expanded.contains(key), visited.insert(key).inserted else { continue }
            await load(url, showHidden: showHidden)
            pending.append(contentsOf: children[key] ?? [])
        }
    }

    /// Opens every folder between the root and `target` so the target's row exists.
    func reveal(_ target: URL, roots: [URL], showHidden: Bool) async {
        let generation = visibilityGeneration
        guard listingHidden == nil || listingHidden == showHidden else { return }
        guard let root = FolderTree.root(containing: target, among: roots) else { return }
        for folder in FolderTree.ancestors(of: target, below: root) {
            guard !Task.isCancelled, generation == visibilityGeneration else { return }
            let key = FolderTree.key(folder)
            if !expanded.contains(key) { expanded.insert(key); persist() }
            if children[key] == nil { await load(folder, showHidden: showHidden) }
        }
    }

    func rows(for roots: [FolderTreeRoot]) -> [Row] {
        if cachedRevision == revision, cachedRoots == roots { return cachedRows }
        var result: [Row] = []
        func add(_ url: URL, name: String, icon: String, depth: Int) {
            let key = FolderTree.key(url)
            let open = expanded.contains(key)
            let known = children[key]
            result.append(Row(url: url, name: name, icon: icon, depth: depth, isExpanded: open, canExpand: known.map { !$0.isEmpty } ?? true, id: key))
            guard open, let known else { return }
            for child in known { add(child, name: child.lastPathComponent, icon: "folder", depth: depth + 1) }
        }
        for root in roots { add(root.url, name: root.name, icon: root.icon, depth: 0) }
        cachedRoots = roots
        cachedRows = result
        cachedRevision = revision
        return result
    }

    private func persist() { defaults.set(Array(expanded).sorted(), forKey: Self.defaultsKey) }
}
