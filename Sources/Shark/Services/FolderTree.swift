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
        return urls.filter { child in
            let values = try? child.resourceValues(forKeys: Set(keys))
            if values?.isPackage == true { return false }
            if values?.isSymbolicLink == true {
                return (try? child.resolvingSymlinksInPath().resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            }
            return values?.isDirectory == true
        }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
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
        var id: String { FolderTree.key(url) }
    }

    static let defaultsKey = "folderTree.expanded"
    private(set) var expanded: Set<String>
    private(set) var children: [String: [URL]] = [:]
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
        let key = FolderTree.key(url)
        expanded.insert(key)
        persist()
        await load(url, showHidden: showHidden)
    }

    func collapse(_ url: URL) {
        expanded.remove(FolderTree.key(url))
        persist()
    }

    /// Re-reads a folder (new or removed subfolders, or a changed hidden-files setting).
    func load(_ url: URL, showHidden: Bool) async {
        let listing = await Task.detached(priority: .userInitiated) {
            FolderTree.childFolders(of: url, showHidden: showHidden)
        }.value
        guard !Task.isCancelled else { return }
        children[FolderTree.key(url)] = listing
    }

    func reloadExpanded(showHidden: Bool) async {
        for path in expanded.sorted() { await load(URL(fileURLWithPath: path, isDirectory: true), showHidden: showHidden) }
    }

    /// Opens every folder between the root and `target` so the target's row exists.
    func reveal(_ target: URL, roots: [URL], showHidden: Bool) async {
        guard let root = FolderTree.root(containing: target, among: roots) else { return }
        for folder in FolderTree.ancestors(of: target, below: root) {
            guard !Task.isCancelled else { return }
            let key = FolderTree.key(folder)
            if !expanded.contains(key) { expanded.insert(key); persist() }
            if children[key] == nil { await load(folder, showHidden: showHidden) }
        }
    }

    func rows(for roots: [FolderTreeRoot]) -> [Row] {
        var result: [Row] = []
        func add(_ url: URL, name: String, icon: String, depth: Int) {
            let key = FolderTree.key(url)
            let open = expanded.contains(key)
            let known = children[key]
            result.append(Row(url: url, name: name, icon: icon, depth: depth, isExpanded: open, canExpand: known.map { !$0.isEmpty } ?? true))
            guard open, let known else { return }
            for child in known { add(child, name: child.lastPathComponent, icon: "folder", depth: depth + 1) }
        }
        for root in roots { add(root.url, name: root.name, icon: root.icon, depth: 0) }
        return result
    }

    private func persist() { defaults.set(Array(expanded).sorted(), forKey: Self.defaultsKey) }
}
