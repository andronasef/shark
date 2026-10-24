import SwiftUI
import AppKit

/// Gallery uses bounded thumbnail decoding instead of showing only a type symbol.
struct FileThumbnailView: View {
    let item: FileItem
    let size: CGFloat
    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: NSImage?

    var body: some View {
        Group {
            if let thumbnail, !item.isDirectory {
                Image(nsImage: thumbnail).resizable().scaledToFit()
            } else {
                FileItemIconView(item: item, size: size)
            }
        }
        .frame(width: size, height: size)
        .task(id: "\(item.url.absoluteString)|\(item.dateModified)|\(size)|\(displayScale)") {
            thumbnail = nil
            guard !item.isDirectory else { return }
            let image = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width: size, height: size), scale: displayScale)
            guard !Task.isCancelled else { return }
            thumbnail = image
        }
    }
}
