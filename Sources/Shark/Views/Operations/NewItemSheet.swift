import SwiftUI

public enum NewItemType: String, Identifiable {
    case folder
    case file

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .folder: return "New Folder"
        case .file: return "New File"
        }
    }

    public var defaultName: String {
        switch self {
        case .folder: return "untitled folder"
        case .file: return "untitled.txt"
        }
    }

    public var icon: String {
        switch self {
        case .folder: return "folder.badge.plus"
        case .file: return "doc.badge.plus"
        }
    }
}

public struct NewItemSheet: View {
    let type: NewItemType
    let parentURL: URL
    let onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var itemName: String
    @State private var isCreating = false
    @State private var errorMessage: String?

    public init(type: NewItemType, parentURL: URL, onCreated: @escaping () -> Void) {
        self.type = type
        self.parentURL = parentURL
        self.onCreated = onCreated
        self._itemName = State(initialValue: type.defaultName)
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                        .font(.headline)
                    Text(L10n.format("In: %@", L10n.literal(parentURL.lastPathComponent)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            TextField(L10n.text("Item name"), text: $itemName)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    createItem()
                }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button(L10n.text("Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(L10n.text("Create")) {
                    createItem()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func createItem() {
        let trimmed = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                switch type {
                case .folder:
                    let url = try await FileOperationsService.shared.createFolder(named: trimmed, at: parentURL)
                    FileUndoService.shared.record(.create(urls: [url], name: "New Folder"))
                case .file:
                    let url = try await FileOperationsService.shared.createFile(named: trimmed, at: parentURL)
                    FileUndoService.shared.record(.create(urls: [url], name: "New File"))
                }
                onCreated()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isCreating = false
            }
        }
    }
}
