import SwiftUI
import AppKit

/// Gallery uses bounded thumbnail decoding instead of showing only a type symbol.
struct FileThumbnailView: View {
    let item: FileItem
    let size: CGFloat
    @Environment(\.displayScale) private var displayScale
    @State private var thumbnail: NSImage?
    @State private var thumbnailURL: URL?

    private var requestSize: CGFloat { ThumbnailService.requestDimension(size) }

    var body: some View {
        Group {
            if let thumbnail, !item.isDirectory {
                Image(nsImage: thumbnail).resizable().scaledToFit()
            } else {
                FileItemIconView(item: item, size: size)
            }
        }
        .frame(width: size, height: size)
        .task(id: "\(item.url.absoluteString)|\(item.dateModified)|\(item.fileSize)|\(item.isDirectory)|\(requestSize)|\(displayScale)") {
            if thumbnailURL != item.url { thumbnail = nil }
            guard !item.isDirectory else { thumbnail = nil; return }
            let image = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width: requestSize, height: requestSize), scale: displayScale)
            guard !Task.isCancelled else { return }
            thumbnail = image
            thumbnailURL = item.url
        }
    }
}
