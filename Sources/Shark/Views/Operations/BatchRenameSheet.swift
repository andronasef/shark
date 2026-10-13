import SwiftUI

public struct BatchRenameSheet: View {
    let items: [FileItem]
    let onRenameComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var findText: String = ""
    @State private var replaceText: String = ""
    @State private var prefix: String = ""
    @State private var suffix: String = ""
    @State private var useNumbering: Bool = false
    @State private var startingNumber: Int = 1
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?

    public init(items: [FileItem], onRenameComplete: @escaping () -> Void) {
        self.items = items
        self.onRenameComplete = onRenameComplete
    }

    private var currentRule: RenameRule {
        RenameRule(
            findText: findText,
            replaceText: replaceText,
            prefix: prefix,
            suffix: suffix,
            useNumbering: useNumbering,
            startingNumber: startingNumber,
            paddingDigits: 2
        )
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Batch Rename (\(items.count) items)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                // Find and Replace
                HStack {
                    Text("Find:")
                        .frame(width: 70, alignment: .trailing)
                    TextField("Text to replace", text: $findText)
                }

                HStack {
                    Text("Replace:")
                        .frame(width: 70, alignment: .trailing)
                    TextField("Replacement text", text: $replaceText)
                }

                Divider()

                // Prefix & Suffix
                HStack {
                    Text("Prefix:")
                        .frame(width: 70, alignment: .trailing)
                    TextField("Prepend to name", text: $prefix)

                    Text("Suffix:")
                    TextField("Append to name", text: $suffix)
                }

                Divider()

                // Sequential Numbering
                Toggle("Add sequential numbering", isOn: $useNumbering)

                if useNumbering {
                    HStack {
                        Text("Start at:")
                            .frame(width: 70, alignment: .trailing)
                        TextField("1", value: $startingNumber, format: .number)
                            .frame(width: 60)
                    }
                }
            }
            .font(.system(size: 12))

            Text("Preview:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Preview List
            List {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let newName = currentRule.apply(to: item.name, index: index)
                    HStack {
                        Text(item.name)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(newName)
                            .fontWeight(.medium)
                            .foregroundColor(item.name != newName ? .accentColor : .primary)
                            .lineLimit(1)
                    }
                    .font(.system(size: 11))
                }
            }
            .frame(height: 140)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Action Buttons
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Rename \(items.count) Items") {
                    performBatchRename()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func performBatchRename() {
        isProcessing = true
        errorMessage = nil

        let urls = items.map(\.url)
        let rule = currentRule

        Task {
            do {
                _ = try await FileOperationsService.shared.batchRename(items: urls, rule: rule)
                await MainActor.run {
                    onRenameComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
}
