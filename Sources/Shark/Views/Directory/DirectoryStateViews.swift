import SwiftUI
import AppKit

// MARK: - Empty State View
public struct DirectoryEmptyStateView: View {
    let isFilterActive: Bool
    let onClearFilter: () -> Void
    let onNewFolder: () -> Void

    public init(
        isFilterActive: Bool,
        onClearFilter: @escaping () -> Void,
        onNewFolder: @escaping () -> Void
    ) {
        self.isFilterActive = isFilterActive
        self.onClearFilter = onClearFilter
        self.onNewFolder = onNewFolder
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle" : "folder.badge.questionmark")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(.secondary.opacity(0.6))

            Text(isFilterActive ? L10n.text("No Matching Items") : L10n.text("This Folder is Empty"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            Text(isFilterActive
                 ? "No items match your active filter."
                 : "Drag files here to move them, or create a new folder."
            )
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 280)

            HStack(spacing: 10) {
                if isFilterActive {
                    Button(L10n.text("Clear Filter")) {
                        onClearFilter()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button(action: onNewFolder) {
                        Label(L10n.text("New Folder"), systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFilterActive ? L10n.text("No matching items in directory filter") : L10n.text("Folder is empty"))
    }
}

// MARK: - Error & Permission Denied State View
public struct DirectoryErrorStateView: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onGoHome: () -> Void
    let onGrantAccess: (() -> Void)?

    public init(
        errorMessage: String,
        onRetry: @escaping () -> Void,
        onGoHome: @escaping () -> Void,
        onGrantAccess: (() -> Void)? = nil
    ) {
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.onGoHome = onGoHome
        self.onGrantAccess = onGrantAccess
    }

    private var isPermissionError: Bool {
        let lower = errorMessage.lowercased()
        return lower.contains("permission") || lower.contains("access denied") || lower.contains("operation not permitted") || lower.contains("not authorized")
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isPermissionError ? "lock.shield.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 46, weight: .light))
                .foregroundColor(isPermissionError ? .orange : .red.opacity(0.85))

            Text(isPermissionError ? L10n.text("Access Restricted") : L10n.text("Cannot Open Folder"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            Text(isPermissionError
                 ? "Shark does not have permission to browse this location. You can grant Full Disk Access in macOS System Settings."
                 : errorMessage
            )
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 320)

            HStack(spacing: 12) {
                if isPermissionError {
                    if let onGrantAccess {
                        Button(L10n.text("Grant Access..."), action: onGrantAccess)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }

                    if onGrantAccess == nil {
                        Button(L10n.text("Open Privacy Settings")) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        Button(L10n.text("Open Privacy Settings")) {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Button(L10n.text("Go to Home"), action: onGoHome)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Button(L10n.text("Try Again"), action: onRetry)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                    Button(L10n.text("Go to Home"), action: onGoHome)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isPermissionError ? L10n.text("Permission denied. Open System Settings to grant Full Disk Access.") : L10n.format("Error: %@", errorMessage))
    }
}

// MARK: - Loading State View
public struct DirectoryLoadingStateView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.85)

            Text(L10n.text("Loading folder contents..."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: true)
        .accessibilityLabel(L10n.text("Loading folder contents"))
    }
}
