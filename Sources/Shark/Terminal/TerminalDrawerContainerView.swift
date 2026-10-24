import SwiftUI
import AppKit

public struct TerminalDrawerContainerView: View {
    @Bindable var session: PTYSession
    @Binding var isPresented: Bool
    @State private var drawerHeight: CGFloat = 220
    @State private var resizeStartHeight: CGFloat?
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
                    Text("App Sandbox Active: Terminal interactive shell is restricted by macOS App Store sandbox policy.")
                }
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
            }

            TerminalView(session: session)
                .frame(height: drawerHeight)
                .overlay(alignment: .bottom) {
                    if !session.isRunning {
                        HStack {
                            Text("Shell exited")
                            if let code = session.exitCode { Text("(\(code))") }
                            Button("Restart") { session.restart() }
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
        alert.messageText = "Terminate this terminal session?"
        alert.informativeText = "This stops the shell and its running commands."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Terminate")
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

            Text("Terminal")
                .font(.system(size: 11, weight: .semibold))

            // Working directory badge
            Text((session.hasReportedDirectory ? "" : "Started in: ") + session.currentWorkingDirectory.path)
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

            Button("Use Current Folder") {
                do {
                    let command = try session.useDirectory(currentDirectory)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    let alert = NSAlert()
                    alert.messageText = "Directory command copied"
                    alert.informativeText = "Paste the copied cd command into an empty shell prompt when you are ready. The terminal's existing input and running commands are preserved."
                    alert.runModal()
                    session.focus()
                } catch { NSAlert(error: error).runModal() }
            }
            .font(.system(size: 10))
            .help("Copy a quoted cd command for the current folder")

            Menu {
                Button("Restart Shell…") {
                    if !session.isRunning || confirmTermination() { session.restart() }
                }
                Button("Terminate Shell…") {
                    if confirmTermination() { session.terminate() }
                }
                .disabled(!session.isRunning)
                Divider()
                Button("Increase Text Size") { session.adjustFontSize(by: 1) }
                Button("Decrease Text Size") { session.adjustFontSize(by: -1) }
                Button("Reset Text Size") { session.resetFontSize() }
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
            .help("Clear Terminal Buffer")

            // Close Drawer button
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close Terminal Drawer (F4)")
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
