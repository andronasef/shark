import AppKit
import SwiftUI

struct DefaultFolderAppControls: View {
    var allowsRestore = false
    @State private var service = DefaultFolderAppService.shared
    @State private var showsManualSetup = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(service.isSharkDefault ? "Shark opens folders by default." : "Current default: \(service.currentApplicationName)")
                .font(.callout)
            Text("Open folders from other apps in Shark. Finder-specific actions such as Reveal in Finder still use Finder.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Make Shark Default") {
                    Task { await service.makeSharkDefault() }
                }
                .disabled(service.isSharkDefault || service.isChanging)
                if allowsRestore {
                    Button("Restore Finder") {
                        Task { await service.restoreFinder() }
                    }
                    .disabled(service.isChanging)
                }
                if service.isChanging {
                    ProgressView().controlSize(.small)
                        .accessibilityLabel("Waiting for macOS to change the default folder app")
                }
            }
            if let error = service.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if allowsRestore || service.requiresManualSetup {
                Button("Manual Setup…") { showsManualSetup = true }
                Text("If you ran a manual command, use Manual Setup’s restore command to undo it before restarting.")
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
    // Do not change NSFileViewer: Shark only claims folder-open events, not Finder reveal events.
    private func command(for identifier: String) -> String {
        "defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=\"public.folder\";LSHandlerRoleAll=\"\(identifier)\";}'"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Manual folder setup")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text("If macOS rejects the default-folder APIs, you can try a manual folder-opening preference instead. It requires restarting macOS and may not work on every version.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Copy one command, paste it into Terminal, and press Return. Restart your Mac, then check the current default in Shark’s General settings. To undo a manual change before restarting, run Restore Finder below—even if the current default still says Finder.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            commandRow("Make Shark the default", identifier: "com.increasinglabs.shark")
            Divider()
            commandRow("Restore Finder", identifier: "com.apple.finder")
            Text("These commands only add a folder-opening preference for your account. They do not grant Full Disk Access or change the default apps for individual file types.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button("Done") { dismiss() }
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
            Button(copiedCommand == identifier ? "Copied" : "Copy Command") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(command(for: identifier), forType: .string)
                copiedCommand = identifier
            }
            .accessibilityLabel("Copy command: \(title)")
        }
    }
}

struct FullDiskAccessControls: View {
    @State private var couldNotOpenSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Optional. Let Shark browse more protected locations, which can include other apps’ private data. You can also grant access to individual folders as you browse.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Full Disk Access Settings…") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
                couldNotOpenSettings = !NSWorkspace.shared.open(url)
            }
            Button("Show Shark in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
            }
            Text("If Shark isn’t listed, click +, then press ⇧⌘G and paste the app location below. Choose Open, enable Shark, and reopen it if macOS asks. Use this running copy if you have more than one Shark installed.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(Bundle.main.bundlePath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Running Shark app location: \(Bundle.main.bundlePath)")
            if couldNotOpenSettings {
                Text("Open System Settings → Privacy & Security → Full Disk Access.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}
