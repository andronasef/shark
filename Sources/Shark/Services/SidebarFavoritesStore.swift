import AppKit
import Observation

struct SidebarFavorite: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var url: URL
    var iconName: String = "folder"

    var isAvailable: Bool {
        var directory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &directory) && directory.boolValue
    }
}

@MainActor
@Observable
final class SidebarFavoritesStore {
    static let shared = SidebarFavoritesStore()
    private(set) var items: [SidebarFavorite]
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key = "sidebar.favorites.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key), let saved = try? JSONDecoder().decode([SidebarFavorite].self, from: data) {
            items = saved
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            items = [
                SidebarFavorite(name: "Applications", url: URL(fileURLWithPath: "/Applications"), iconName: "app.badge"),
                SidebarFavorite(name: "Desktop", url: home.appendingPathComponent("Desktop"), iconName: "macwindow"),
                SidebarFavorite(name: "Documents", url: home.appendingPathComponent("Documents"), iconName: "doc"),
                SidebarFavorite(name: "Downloads", url: home.appendingPathComponent("Downloads"), iconName: "arrow.down.circle")
            ]
            // Discover a real Projects folder instead of assigning an unrelated path.
            if let projects = [home.appendingPathComponent("Projects"), home.appendingPathComponent("Developer")]
                .first(where: { SidebarFavorite(name: "Projects", url: $0).isAvailable }) {
                items.insert(SidebarFavorite(name: "Projects", url: projects), at: 0)
            }
            save()
        }
    }

    @discardableResult
    func insert(_ urls: [URL], at index: Int) -> Bool {
        for u in urls {
            _ = try? SecurityScopedBookmarkManager.shared.saveBookmark(for: u)
        }
        let valid = urls.map(\.standardizedFileURL).filter { url in
            items.contains(where: { $0.url.standardizedFileURL.path == url.path }) || SidebarFavorite(name: "", url: url).isAvailable
        }
        guard !valid.isEmpty else { return false }
        // An existing favorite is moved, not duplicated. Preserve its label and identity.
        let unique = valid.reduce(into: [URL]()) { result, url in if !result.contains(where: { $0.path == url.path }) { result.append(url) } }
        let moving = unique.map { url in items.first(where: { $0.url.standardizedFileURL.path == url.path }) ?? SidebarFavorite(name: url.lastPathComponent, url: url) }
        let paths = Set(unique.map(\.path))
        let removedBefore = items.prefix(max(0, min(index, items.count))).filter { paths.contains($0.url.standardizedFileURL.path) }.count
        items.removeAll { paths.contains($0.url.standardizedFileURL.path) }
        items.insert(contentsOf: moving, at: max(0, min(index - removedBefore, items.count)))
        save()
        return true
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    static func contains(_ url: URL, currentFolder: URL) -> Bool {
        let ancestor = url.standardizedFileURL.pathComponents
        let current = currentFolder.standardizedFileURL.pathComponents
        return current.count > ancestor.count && current.starts(with: ancestor)
    }

    func relocate(_ id: UUID, to url: URL) {
        guard SidebarFavorite(name: "", url: url).isAvailable,
              let index = items.firstIndex(where: { $0.id == id }),
              !items.contains(where: { $0.id != id && $0.url.standardizedFileURL.path == url.standardizedFileURL.path }) else { return }
        items[index].url = url.standardizedFileURL
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: key) }
    }
}
