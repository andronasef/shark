import SwiftUI
import AppKit
import AVKit

/// NSImageView that never imposes its image size on layout, so SwiftUI's frame decides.
private final class FlexibleImageView: NSImageView {
    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric) }
}

/// Plays animated formats (GIF, APNG) that SwiftUI's `Image` renders as a still frame.
private struct AnimatedImageView: NSViewRepresentable {
    let image: NSImage

    func makeNSView(context: Context) -> NSImageView {
        let view = FlexibleImageView(image: image)
        view.animates = true
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }

    func updateNSView(_ view: NSImageView, context: Context) {
        view.image = image
    }
}

private extension NSImage {
    var isAnimated: Bool {
        ((representations.first as? NSBitmapImageRep)?.value(forProperty: .frameCount) as? Int ?? 1) > 1
    }
}

/// Inline AVKit player: seek bar, play/pause and volume, with no window of its own.
private struct MediaPlayerView: NSViewRepresentable {
    let url: URL
    let autoplay: Bool

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .inline
        view.showsFullScreenToggleButton = false
        view.player = AVPlayer(url: url)
        if autoplay { view.player?.play() }
        return view
    }

    func updateNSView(_ view: AVPlayerView, context: Context) {}

    static func dismantleNSView(_ view: AVPlayerView, coordinator: ()) {
        view.player?.pause()
        view.player = nil
    }
}

public struct HoverPreviewCard: View {
    public let item: FileItem
    @State private var previewData: HoverPreviewData = .unsupported
    @State private var isLoading = true
    @AppStorage("hoverPreviewAutoplay") private var autoplay = true

    private static let maxImageSize = CGSize(width: 480, height: 360)

    public init(item: FileItem) {
        self.item = item
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Name and Type
            HStack(spacing: 6) {
                FileItemIconView(item: item, size: 16)
                    .frame(width: 16, height: 16)
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }

            Divider()
                .opacity(0.3)

            // Content preview
            Group {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.7)
                        Spacer()
                    }
                    .frame(width: 240, height: 120)
                } else {
                    switch previewData {
                    case .image(let image, let dimensions, let sizeFormatted):
                        let size = fitted(image.size)
                        VStack(alignment: .leading, spacing: 6) {
                            imageView(image, size: size)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            HStack {
                                if dimensions != .zero {
                                    Text("\(Int(dimensions.width)) × \(Int(dimensions.height)) px")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(sizeFormatted)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: max(size.width, 160))

                    case .text(let lines, let totalLines, let encoding, let sizeFormatted, let truncated):
                        VStack(alignment: .leading, spacing: 4) {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                                    Text(line.isEmpty ? " " : line)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.primary.opacity(0.9))
                                        .lineLimit(1)
                                }
                            }
                            .padding(8)
                            .frame(width: 440, alignment: .leading)
                            .background(Color.black.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            HStack {
                                Text("\(totalLines)\(truncated ? "+" : "") lines · \(encoding)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(sizeFormatted)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }

                    case .media(let url, let isVideo, let sizeFormatted):
                        VStack(alignment: .leading, spacing: 6) {
                            MediaPlayerView(url: url, autoplay: autoplay)
                                .frame(width: isVideo ? 400 : 320, height: isVideo ? 240 : 64)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(sizeFormatted)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }

                    case .unsupported:
                        VStack(alignment: .center, spacing: 4) {
                            Image(systemName: "doc")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("No preview available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 180, height: 80)
                    }
                }
            }
        }
        .padding(12)
        .liquidGlassCard(cornerRadius: 12, material: .popover)
        .task(id: item.url) {
            isLoading = true
            previewData = await HoverPreviewService.shared.fetchPreview(for: item.url)
            isLoading = false
        }
    }

    /// Scales down to fit the preview bounds; small images stay at their natural size. Extreme
    /// aspect ratios (long page screenshots, banners) get a square window onto the image instead
    /// of an unreadable sliver.
    private func fitted(_ size: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return CGSize(width: 160, height: 120) }
        if Self.isExtreme(size) { return CGSize(width: 360, height: 360) }
        let scale = min(1, Self.maxImageSize.width / size.width, Self.maxImageSize.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private static func isExtreme(_ size: CGSize) -> Bool {
        let ratio = size.width / size.height
        return ratio < 1.0 / 3 || ratio > 3
    }

    @ViewBuilder
    private func imageView(_ image: NSImage, size: CGSize) -> some View {
        if image.isAnimated {
            AnimatedImageView(image: image)
        } else if Self.isExtreme(image.size) {
            // Fill the window and show the start of the image (top of a page, left of a banner).
            Image(nsImage: image).resizable().scaledToFill()
                .frame(width: size.width, height: size.height, alignment: image.size.height > image.size.width ? .top : .leading)
                .clipped()
        } else {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
        }
    }
}
