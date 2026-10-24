import SwiftUI
import AppKit

public struct TerminalDrawerContainerView: View {
    @Bindable var session: PTYSession
    @Binding var isPresented: Bool
    @State private var drawerHeight: CGFloat = 220
    @State private var resizeStartHeight: CGFloat?
    @State private var copiedCommand = false
    let currentDirectory: URL

    public init(session: PTYSession, isPresented: Binding<Bool>, currentDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentDirectory = currentDirectory
        self.session = session
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle and resize bar
            resizeHandle

            // Terminal Header Bar
            headerBar

            if SecurityScopedBookmarkManager.shared.isSandboxed {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield")
                    Text(L10n.text("App Sandbox Active: Terminal interactive shell is restricted by macOS App Store sandbox policy."))
                }
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
            }

            TerminalView(session: session)
                .environment(\.layoutDirection, .leftToRight)
                .frame(height: drawerHeight)
                .overlay(alignment: .bottom) {
                    if !session.isRunning {
                        HStack {
                            Text(L10n.text("Shell exited"))
                            if let code = session.exitCode { Text("(\(code))") }
                            Button(L10n.text("Restart")) { session.restart() }
                        }
                        .font(.system(size: 12))
                        .padding(8)
                        .background(.regularMaterial)
                    }
                }
        }
        .background(Color(white: 0.1))
    }

    private func confirmTermination() -> Bool {
        let alert = NSAlert()
        alert.messageText = L10n.text("Terminate this terminal session?")
        alert.informativeText = L10n.text("This stops the shell and its running commands.")
        alert.addButton(withTitle: L10n.text("Cancel"))
        alert.addButton(withTitle: L10n.text("Terminate"))
        return alert.runModal() == .alertSecondButtonReturn
    }

    private var resizeHandle: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 3)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if resizeStartHeight == nil { resizeStartHeight = drawerHeight }
                        let newHeight = (resizeStartHeight ?? drawerHeight) - value.translation.height
                        let available = session.terminalView?.window?.contentView?.bounds.height ?? 720
                        drawerHeight = min(max(newHeight, 100), max(100, available - 180))
                    }
                    .onEnded { _ in resizeStartHeight = nil }
            )
            .cursor(.resizeUpDown)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 11))
                .foregroundColor(.accentColor)

            Text(L10n.text("Terminal"))
                .font(.system(size: 11, weight: .semibold))

            // Working directory badge
            Text((session.hasReportedDirectory ? "" : L10n.text("Started in: ")) + session.currentWorkingDirectory.path)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )

            Spacer()

            Button(copiedCommand ? L10n.text("Directory command copied") : L10n.text("Use Current Folder")) {
                do {
                    let command = try session.useDirectory(currentDirectory)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    // Paste (⌘V) into an empty prompt when ready; existing input and programs stay untouched.
                    copiedCommand = true
                    session.focus()
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        copiedCommand = false
                    }
                } catch { NSAlert(error: error).runModal() }
            }
            .font(.system(size: 10))
            .help(L10n.text("Copy a quoted cd command for the current folder"))

            Menu {
                Button(L10n.text("Restart Shell…")) {
                    if !session.isRunning || confirmTermination() { session.restart() }
                }
                Button(L10n.text("Terminate Shell…")) {
                    if confirmTermination() { session.terminate() }
                }
                .disabled(!session.isRunning)
                Divider()
                Button(L10n.text("Increase Text Size")) { session.adjustFontSize(by: 1) }
                Button(L10n.text("Decrease Text Size")) { session.adjustFontSize(by: -1) }
                Button(L10n.text("Reset Text Size")) { session.resetFontSize() }
            } label: { Image(systemName: "ellipsis.circle") }
            .menuStyle(.borderlessButton)
            .frame(width: 20)

            // Clear button
            Button(action: {
                session.clear()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.text("Clear Terminal Buffer"))

            // Close Drawer button
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help(L10n.text("Close Terminal Drawer (F4)"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(white: 0.14))
        .overlay(Divider(), alignment: .bottom)
    }
}

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
