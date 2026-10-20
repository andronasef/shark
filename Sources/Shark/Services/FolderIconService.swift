import AppKit
import SwiftUI

@MainActor
public final class FolderIconService {
    public static let shared = FolderIconService()

    public enum FolderColor: String, CaseIterable, Identifiable {
        case blue = "blue"
        case purple = "purple"
        case green = "green"
        case orange = "orange"
        case red = "red"
        case yellow = "yellow"
        case lime = "lime"
        case gray = "gray"
        case black = "black"

        public var id: String { rawValue }

        public var displayName: String {
            rawValue.capitalized
        }
    }

    private var cachedIcons: [String: NSImage] = [:]

    private init() {}

    /// Locates the Assets/Icons folder either inside Bundle.main.resourceURL or next to project root
    private func iconURL(for color: FolderColor) -> URL? {
        let filename = "macos-folder-\(color.rawValue)512x512@2x.svg"

        // 1. Check inside App Bundle Resources
        if let resourceURL = Bundle.main.resourceURL {
            let inBundle = resourceURL.appendingPathComponent("Icons").appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: inBundle.path) {
                return inBundle
            }
            let directInBundle = resourceURL.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: directInBundle.path) {
                return directInBundle
            }
        }

        // 2. Fallback to developer workspace Assets/Icons
        let devPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Assets/Icons")
            .appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: devPath.path) {
            return devPath
        }

        // 3. Absolute known path
        let fixedPath = URL(fileURLWithPath: "/Users/andrew/Documents/Work/Dev/Projects/Personalss/shark/Assets/Icons/\(filename)")
        if FileManager.default.fileExists(atPath: fixedPath.path) {
            return fixedPath
        }

        return nil
    }

    public func folderIcon(color: FolderColor = .blue) -> NSImage? {
        let key = color.rawValue
        if let cached = cachedIcons[key] {
            return cached
        }

        guard let url = iconURL(for: color),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        cachedIcons[key] = image
        return image
    }
}
