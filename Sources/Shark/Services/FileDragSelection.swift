import Foundation

enum FileDragSelection {
    static func urls(dragged: URL, selected: Set<URL>, ordered: [URL]) -> [URL] {
        guard selected.contains(dragged) else { return [dragged] }
        return normalized(ordered.filter { selected.contains($0) })
    }

    /// External drags can contain duplicates, or both a directory and its children.
    static func normalized(_ urls: [URL]) -> [URL] {
        var seen = Set<URL>()
        let unique = urls.filter(\.isFileURL).map(\.standardizedFileURL).filter { seen.insert($0).inserted }
        return unique.filter { candidate in
            !unique.contains { parent in
                parent != candidate && candidate.path.hasPrefix(parent.path.hasSuffix("/") ? parent.path : parent.path + "/")
            }
        }
    }
}
