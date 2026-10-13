import SwiftUI

public struct TerminalDrawerContainerView: View {
    @Bindable var session: PTYSession
    @Binding var isPresented: Bool
    @State private var drawerHeight: CGFloat = 220

    public init(session: PTYSession, isPresented: Binding<Bool>) {
        self.session = session
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle and resize bar
            resizeHandle

            // Terminal Header Bar
            headerBar

            // Terminal NSView
            TerminalView(session: session)
                .frame(height: drawerHeight)
        }
        .background(Color(white: 0.1))
        .onAppear {
            if !session.isRunning {
                session.start()
            }
        }
    }

    private var resizeHandle: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 3)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newHeight = drawerHeight - value.translation.height
                        drawerHeight = min(max(newHeight, 120), 500)
                    }
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
            Text(session.currentWorkingDirectory.path)
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
