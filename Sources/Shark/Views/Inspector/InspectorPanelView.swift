import SwiftUI
import AppKit

public struct InspectorPanelView: View {
    let targetURL: URL
    @Binding var isPresented: Bool

    @State private var metadata: FileMetadata?
    @State private var thumbnail: NSImage?
    @State private var sha256: String?
    @State private var isCalculatingHash = false

    public init(targetURL: URL, isPresented: Binding<Bool>) {
        self.targetURL = targetURL
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Preview & Title
                    previewSection

                    Divider()

                    if let meta = metadata {
                        // General Attributes
                        generalSection(meta)

                        Divider()

                        // POSIX Permissions
                        permissionsSection(meta)

                        // Media Section (if applicable)
                        if let dimensions = meta.imageDimensions {
                            Divider()
                            mediaSection(dimensions)
                        }

                        if !meta.isDirectory {
                            Divider()
                            checksumSection
                        }
                    } else {
                        ProgressView()
                            .padding(.top, 40)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: targetURL) {
            await loadMetadata()
        }
    }

    private var headerBar: some View {
        HStack {
            Label("Information", systemImage: "info.circle")
                .font(.system(size: 12, weight: .semibold))

            Spacer()

            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close Inspector (F11)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var previewSection: some View {
        VStack(spacing: 8) {
            if let thumb = thumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            } else {
                Image(systemName: metadata?.isDirectory == true ? "folder.fill" : "doc.fill")
                    .font(.system(size: 64))
                    .foregroundColor(metadata?.isDirectory == true ? .accentColor : .secondary)
                    .frame(width: 96, height: 96)
            }

            Text(metadata?.name ?? targetURL.lastPathComponent)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(metadata?.kindDescription ?? "")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func generalSection(_ meta: FileMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("General")

            metadataRow("Size", meta.isDirectory ? "--" : "\(meta.formattedSize) (\(meta.fileSize.formatted()) bytes)")

            HStack(alignment: .top) {
                Text("Where")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 65, alignment: .leading)

                Text(meta.url.deletingLastPathComponent().path)
                    .font(.system(size: 11))
                    .lineLimit(2)
                    .truncationMode(.middle)

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(meta.url.path, forType: .string)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Copy Path")
            }

            if let mod = meta.dateModified {
                metadataRow("Modified", mod.formatted(date: .abbreviated, time: .shortened))
            }
            if let crt = meta.dateCreated {
                metadataRow("Created", crt.formatted(date: .abbreviated, time: .shortened))
            }
            if let acc = meta.dateAccessed {
                metadataRow("Accessed", acc.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private func permissionsSection(_ meta: FileMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("POSIX Permissions")

            metadataRow("Mode", "\(meta.octalPermissions) (\(meta.symbolicPermissions))")
            metadataRow("Owner", meta.ownerName)
            metadataRow("Group", meta.groupName)
        }
    }

    private func mediaSection(_ dimensions: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Media Details")

            metadataRow("Dimensions", "\(Int(dimensions.width)) × \(Int(dimensions.height)) px")
        }
    }

    private var checksumSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Checksum")

            if let hash = sha256 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("SHA-256")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(hash, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Copy SHA-256")
                    }
                    Text(hash)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
            } else if isCalculatingHash {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Calculating SHA-256...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Calculate SHA-256") {
                    calculateHash()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
    }

    private func metadataRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.primary)
            Spacer()
        }
    }

    private func loadMetadata() async {
        self.sha256 = nil
        let meta = await MetadataExtractor.shared.extractMetadata(for: targetURL)
        self.metadata = meta

        let thumb = await ThumbnailService.shared.thumbnail(for: targetURL, size: CGSize(width: 192, height: 192))
        self.thumbnail = thumb
    }

    private func calculateHash() {
        isCalculatingHash = true
        Task {
            let hash = await MetadataExtractor.shared.computeSHA256(for: targetURL)
            await MainActor.run {
                self.sha256 = hash
                self.isCalculatingHash = false
            }
        }
    }
}
