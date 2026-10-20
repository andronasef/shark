import SwiftUI
import AppKit

public struct HoverPreviewCard: View {
    public let item: FileItem
    @State private var previewData: HoverPreviewData = .unsupported
    @State private var isLoading = true

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
                    .frame(height: 120)
                } else {
                    switch previewData {
                    case .image(let image, let dimensions, let sizeFormatted):
                        VStack(alignment: .leading, spacing: 6) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 280, maxHeight: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .shadow(radius: 2)

                            HStack {
                                Text("\(Int(dimensions.width)) × \(Int(dimensions.height)) px")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(sizeFormatted)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }

                    case .text(let lines, let totalLines, _, let sizeFormatted):
                        VStack(alignment: .leading, spacing: 4) {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(lines.prefix(10).enumerated()), id: \.offset) { _, line in
                                    Text(line.isEmpty ? " " : line)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.primary.opacity(0.9))
                                        .lineLimit(1)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: 320, alignment: .leading)
                            .background(Color.black.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            HStack {
                                Text("\(totalLines) lines")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(sizeFormatted)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
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
}
