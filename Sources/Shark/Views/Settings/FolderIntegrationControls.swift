import AppKit
import SwiftUI

struct DefaultFolderAppControls: View {
    var allowsRestore = false
    @State private var service = DefaultFolderAppService.shared
    @State private var showsManualSetup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(service.isSharkDefault ? L10n.text("Shark opens folders by default.") : L10n.format("Current default: %@", service.currentApplicationName))
                .font(.callout)
            Text(L10n.text("Open folders from other apps in Shark. Finder-specific actions such as Reveal in Finder still use Finder."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(L10n.text("Make Shark Default")) {
                    Task { await service.makeSharkDefault() }
                }
                .disabled(service.isSharkDefault || service.isChanging)
                if allowsRestore {
                    Button(L10n.text("Restore Finder")) {
                        Task { await service.restoreFinder() }
                    }
                    .disabled(service.isChanging)
                }
                if service.isChanging {
                    ProgressView().controlSize(.small)
                        .accessibilityLabel(L10n.text("Waiting for macOS to change the default folder app"))
                }
            }
            if let error = service.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if allowsRestore || service.requiresManualSetup {
                Button(L10n.text("Manual Setup…")) { showsManualSetup = true }
                Text(L10n.text("If you ran a manual command, use Manual Setup’s restore command to undo it before restarting."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showsManualSetup) { ManualFolderSetupView() }
        .onAppear { service.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            service.refresh()
        }
    }
}

private struct ManualFolderSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copiedCommand: String?

    // Same folder-handler preference used in other Mac file managers' manual setup guides.
    // Shark never writes NSFileViewer itself; it does answer Reveal events if the user sets it.
    private func command(for identifier: String) -> String {
        if identifier == Self.fileViewerKey { return "defaults write -g NSFileViewer -string com.increasinglabs.shark" }
        if identifier == Self.fileViewerRestoreKey { return "defaults delete -g NSFileViewer" }
        return "defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=\"public.folder\";LSHandlerRoleAll=\"\(identifier)\";}'"
    }

    private static let fileViewerKey = "NSFileViewer"
    private static let fileViewerRestoreKey = "NSFileViewer.restore"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.text("Manual folder setup"))
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(L10n.text("If macOS rejects the default-folder APIs, you can try a manual folder-opening preference instead. It requires restarting macOS and may not work on every version."))
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.text("Copy one command, paste it into Terminal, and press Return. Restart your Mac, then check the current default in Shark’s General settings. To undo a manual change before restarting, run Restore Finder below—even if the current default still says Finder."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            commandRow("Make Shark the default", identifier: "com.increasinglabs.shark")
            Divider()
            commandRow("Restore Finder", identifier: "com.apple.finder")
            Divider()
            Text(L10n.text("Alternative: use Shark as the file viewer"))
                .font(.headline)
            Text(L10n.text("If the commands above do not work, this makes “Show in Folder” and “Reveal” from other apps open Shark on the right folder with the item selected. It takes effect the next time you sign in or restart apps."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            commandRow("Use Shark as the file viewer", identifier: Self.fileViewerKey)
            commandRow("Restore the system file viewer", identifier: Self.fileViewerRestoreKey)
            Text(L10n.text("These commands only add a folder-opening preference for your account. They do not grant Full Disk Access or change the default apps for individual file types."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button(L10n.text("Done")) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 560)
    }

    private func commandRow(_ title: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(command(for: identifier))
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Button(copiedCommand == identifier ? L10n.text("Copied") : L10n.text("Copy Command")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command(for: identifier), forType: .string)
                copiedCommand = identifier
            }
            .accessibilityLabel(L10n.format("Copy command: %@", title))
        }
    }
}

struct FullDiskAccessControls: View {
    @State private var couldNotOpenSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("Optional. Let Shark browse more protected locations, which can include other apps’ private data. You can also grant access to individual folders as you browse."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.text("Open Full Disk Access Settings…")) {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
                couldNotOpenSettings = !NSWorkspace.shared.open(url)
            }
            Button(L10n.text("Show Shark in Finder")) {
                NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
            }
            Text(L10n.text("If Shark isn’t listed, click +, then press ⇧⌘G and paste the app location below. Choose Open, enable Shark, and reopen it if macOS asks. Use this running copy if you have more than one Shark installed."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(Bundle.main.bundlePath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(L10n.format("Running Shark app location: %@", L10n.literal(Bundle.main.bundlePath)))
            if couldNotOpenSettings {
                Text(L10n.text("Open System Settings → Privacy & Security → Full Disk Access."))
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
