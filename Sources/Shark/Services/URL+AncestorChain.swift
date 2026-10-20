import Foundation

extension URL {
    /// Directories from "/" down to this URL, inclusive. Built from path components so it always
    /// terminates: repeatedly calling `deletingLastPathComponent()` on "/" can climb "/../../.."
    /// forever, which hung the path bar when the current folder was the disk root.
    var ancestorChain: [URL] {
        let standardized = standardizedFileURL
        var cursor = URL(fileURLWithPath: "/")
        var chain = [cursor]
        for component in standardized.pathComponents where component != "/" {
            cursor = cursor.appendingPathComponent(component, isDirectory: true)
            chain.append(cursor)
        }
        if chain.count > 1 { chain[chain.count - 1] = standardized }
        return chain
    }
}
