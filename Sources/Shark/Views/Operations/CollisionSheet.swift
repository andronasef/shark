import SwiftUI

/// Asks what to do when a copy, move, paste or drop meets a name that is already taken.
struct CollisionSheet: View {
    let prompt: CollisionPrompt
    let answer: (CollisionChoice, Bool) -> Void
    @State private var applyToAll = false

    private var question: String {
        L10n.format(prompt.mode == .move
                    ? "An item named “%@” already exists in this location. Do you want to replace it with the one you’re moving?"
                    : "An item named “%@” already exists in this location. Do you want to replace it with the one you’re copying?",
                    L10n.literal(prompt.incoming.name))
    }

    private var incomingIsNewer: Bool? {
        prompt.incoming.dateModified == prompt.existing.dateModified ? nil : prompt.incoming.dateModified > prompt.existing.dateModified
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.format("“%@” already exists", L10n.literal(prompt.incoming.name)))
                    .font(.headline)
                Text(question)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: 12) {
                ItemColumn(title: L10n.text("Existing item"), item: prompt.existing,
                           badge: incomingIsNewer.map { $0 ? L10n.text("Older") : L10n.text("Newer") })
                ItemColumn(title: L10n.text("New item"), item: prompt.incoming,
                           badge: incomingIsNewer.map { $0 ? L10n.text("Newer") : L10n.text("Older") })
            }

            if prompt.mayRepeat {
                Toggle(L10n.text("Apply to all"), isOn: $applyToAll)
            }

            HStack {
                Button(L10n.text("Stop")) { answer(.stop, false) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(L10n.text("Skip")) { answer(.skip, applyToAll) }
                Button(L10n.text("Replace")) { answer(.replace, applyToAll) }
                if prompt.canMerge {
                    Button(L10n.text("Merge")) { answer(.merge, applyToAll) }
                }
                // Keep Both loses nothing, so it is the default.
                Button(L10n.text("Keep Both")) { answer(.keepBoth, applyToAll) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
        .interactiveDismissDisabled()
    }
}

private struct ItemColumn: View {
    let title: String
    let item: FileItem
    let badge: String?

    private var detail: String {
        let size = item.isDirectory || item.isPackage
            ? item.kindDescription
            : ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file)
        return "\(size) · \(item.dateModified.formatted(date: .abbreviated, time: .shortened))"
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            FileThumbnailView(item: item, size: 64)
            Text(item.name)
                .font(.callout.weight(.medium))
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let badge {
                Text(badge).font(.caption.weight(.semibold)).foregroundStyle(.tint)
            } else {
                Text(" ").font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
