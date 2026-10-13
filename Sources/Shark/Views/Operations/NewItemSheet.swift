import SwiftUI

public enum NewItemType {
    case folder
    case file

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
        VStack(alignment: .leading, spacing: 16) {
            Label(type.title, systemImage: type.icon)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Enter name", text: $itemName)
                    .textFieldStyle(.roundedBorder)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createItem()
                }
                .buttonStyle(.borderedProminent)
                .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    private func createItem() {
        isCreating = true
        errorMessage = nil

        let name = itemName.trimmingCharacters(in: .whitespaces)

        Task {
            do {
                switch type {
                case .folder:
                    _ = try await FileOperationsService.shared.createFolder(named: name, at: parentURL)
                case .file:
                    _ = try await FileOperationsService.shared.createFile(named: name, at: parentURL)
                }

                await MainActor.run {
                    onCreated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isCreating = false
                }
            }
        }
    }
}
