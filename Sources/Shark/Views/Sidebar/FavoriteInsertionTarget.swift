import AppKit
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let sharkFavorite = UTType(exportedAs: "org.shark.favorite-shortcut")
}

/// A shortcut drag is intentionally distinct from a file drag: reordering must never move a folder on disk.
struct FavoriteShortcutTransfer: Codable, Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .sharkFavorite)
    }
}

@MainActor
enum SidebarDropReader {
    static func urls(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.sharkFavorite.identifier) {
                let data: Data? = await withCheckedContinuation { continuation in
                    provider.loadDataRepresentation(forTypeIdentifier: UTType.sharkFavorite.identifier) { data, _ in
                        continuation.resume(returning: data)
                    }
                }
                if let data, let shortcut = try? JSONDecoder().decode(FavoriteShortcutTransfer.self, from: data) {
                    urls.append(shortcut.url)
                }
            } else if let url = await withCheckedContinuation({ continuation in
                _ = provider.loadObject(ofClass: URL.self) { url, _ in continuation.resume(returning: url) }
            }) { urls.append(url) }
        }
        return urls
    }
}

/// Separate insertion targets make adding shortcuts distinct from dropping files into folders.
struct FavoriteInsertionTarget: View {
    let insert: ([URL]) -> Bool
    @State private var isTargeted = false

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: 8)
            .overlay {
                if isTargeted {
                    Capsule().fill(Color.accentColor).frame(height: 2)
                        .padding(.horizontal, 10)
                }
            }
            .contentShape(Rectangle())
            .onDrop(of: [.sharkFavorite, .fileURL], isTargeted: $isTargeted) { providers in
                Task { @MainActor in _ = insert(await SidebarDropReader.urls(from: providers)) }
                return !providers.isEmpty
            }
            .accessibilityHidden(true)
    }
}

struct SidebarRowFeedback: ViewModifier {
    let isFocused: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(isHovered ? 0.045 : 0)))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 1.5)
                }
            }
            .onHover { isHovered = $0 }
    }
}
