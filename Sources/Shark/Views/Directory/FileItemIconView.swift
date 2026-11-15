import SwiftUI
import AppKit

public struct FileItemIconView: View {
    public let item: FileItem
    public let size: CGFloat

    public init(item: FileItem, size: CGFloat = 18) {
        self.item = item
        self.size = size
    }

    public var body: some View {
        Group {
            if item.isDirectory && !item.isPackage {
                if let customFolder = FolderIconService.shared.folderIcon(color: .blue) {
                    Image(nsImage: customFolder)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: size * 0.8))
                        .foregroundColor(.accentColor)
                        .frame(width: size, height: size)
                }
            } else if item.isPackage {
                // Apps and other bundles carry their own icon, as in Finder.
                Image(nsImage: PackageIconCache.icon(for: item.url))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: item.systemIconName)
                    .font(.system(size: size * 0.8))
                    .foregroundColor(item.isPackage ? .orange : .secondary)
                    .frame(width: size, height: size)
            }
        }
    }
}

/// NSWorkspace icons for bundles, cached by path so scrolling a long Applications folder stays cheap.
@MainActor
enum PackageIconCache {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(for url: URL) -> NSImage {
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(icon, forKey: key)
        return icon
    }
}
