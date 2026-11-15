import SwiftUI

/// A small iCloud status mark at the corner of an icon. Synchronized and non-cloud items show nothing.
struct CloudBadge: View {
    let item: FileItem
    let size: CGFloat

    static func description(for item: FileItem) -> String? {
        switch item.cloudState {
        case .error(let message): return L10n.format("iCloud error: %@", L10n.literal(message))
        case .downloading: return L10n.text("Downloading from iCloud")
        case .uploading: return L10n.text("Uploading to iCloud")
        case .cloudOnly: return L10n.text("In iCloud, not downloaded")
        case .synced, .notCloud: return item.isCloudShared ? L10n.text("Shared in iCloud") : nil
        }
    }

    private var symbol: String? {
        switch item.cloudState {
        case .error: return "exclamationmark.icloud.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .uploading: return "icloud.and.arrow.up.fill"
        case .cloudOnly: return "icloud.and.arrow.down"
        case .synced, .notCloud: return item.isCloudShared ? "person.2.circle.fill" : nil
        }
    }

    var body: some View {
        if let symbol, let text = Self.description(for: item) {
            let isError: Bool = { if case .error = item.cloudState { return true }; return false }()
            Image(systemName: symbol)
                .font(.system(size: max(9, size * 0.34), weight: .semibold))
                .foregroundStyle(isError ? Color.red : Color.accentColor)
                .padding(1)
                .background(.thinMaterial, in: Circle())
                .help(text)
                .accessibilityLabel(text)
        }
    }
}

extension View {
    func cloudBadge(_ item: FileItem, size: CGFloat) -> some View {
        overlay(alignment: .bottomTrailing) { CloudBadge(item: item, size: size).offset(x: 3, y: 3) }
    }
}
