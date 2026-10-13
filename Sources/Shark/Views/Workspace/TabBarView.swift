import SwiftUI

public struct TabBarView: View {
    @Bindable var workspaceState: WorkspaceState

    public init(workspaceState: WorkspaceState) {
        self.workspaceState = workspaceState
    }

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(workspaceState.tabs) { tab in
                        let isActive = (tab.id == workspaceState.activeTabID)

                        Button(action: {
                            workspaceState.selectTab(id: tab.id)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.isSplit ? "rectangle.split.2x1.fill" : "folder.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(isActive ? .accentColor : .secondary)

                                Text(tab.title)
                                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                                    .lineLimit(1)
                                    .frame(maxWidth: 160)

                                if workspaceState.tabs.count > 1 {
                                    Button(action: {
                                        workspaceState.closeTab(id: tab.id)
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(3)
                                            .contentShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isActive ? Color(nsColor: .windowBackgroundColor) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
            }

            // New Tab button
            Button(action: {
                workspaceState.newTab()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            .help("New Tab (⌘T)")

            Spacer()
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .overlay(Divider(), alignment: .bottom)
    }
}
