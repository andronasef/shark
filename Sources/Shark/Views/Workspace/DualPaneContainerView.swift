import SwiftUI

public struct DualPaneContainerView: View {
    @Bindable var tab: WorkspaceTab

    public init(tab: WorkspaceTab) {
        self.tab = tab
    }

    public var body: some View {
        Group {
            if !tab.isSplit {
                singlePaneView(for: tab.primaryPane, identifier: .primary)
            } else {
                HSplitView {
                    paneWrapper(for: tab.primaryPane, identifier: .primary, title: "Left Pane")
                        .frame(minWidth: 240)

                    paneWrapper(for: tab.secondaryPane, identifier: .secondary, title: "Right Pane")
                        .frame(minWidth: 240)
                }
            }
        }
    }

    @ViewBuilder
    private func singlePaneView(for state: NavigationState, identifier: PaneIdentifier) -> some View {
        DirectoryView(navigationState: state, pane: identifier)
            .contentShape(Rectangle())
            .onTapGesture {
                tab.activePane = identifier
            }
    }

    @ViewBuilder
    private func paneWrapper(for state: NavigationState, identifier: PaneIdentifier, title: String) -> some View {
        let isActive = (tab.activePane == identifier)

        VStack(spacing: 0) {
            // Pane Header Status
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? Color.accentColor : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)

                Text(state.currentURL.lastPathComponent.isEmpty ? "Macintosh HD" : state.currentURL.lastPathComponent)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)

                Spacer()

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Button(action: {
                    tab.isSplit = false
                    tab.activePane = .primary
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Split View (F3)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                isActive
                    ? Color.accentColor.opacity(0.12)
                    : Color(nsColor: .controlBackgroundColor).opacity(0.6)
            )

            Divider()

            DirectoryView(navigationState: state, pane: identifier)
                .contentShape(Rectangle())
                .onTapGesture {
                    tab.activePane = identifier
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isActive ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}
