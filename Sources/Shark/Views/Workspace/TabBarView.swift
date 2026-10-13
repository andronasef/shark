import SwiftUI
import Inject

public struct TabBarView: View {
    @ObserveInjection var inject
    @Bindable var workspaceState: WorkspaceState

    public init(workspaceState: WorkspaceState) {
        self.workspaceState = workspaceState
    }

    public var body: some View {
        HStack(spacing: 0) {
            if workspaceState.tabs.count <= 1, let singleTab = workspaceState.tabs.first {
                // Finder single-tab bar design
                Spacer()
                Text(singleTab.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    workspaceState.newTab()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .help("New Tab (⌘T)")
            } else {
                // Multi-tab bar
                HStack(spacing: 1) {
                    ForEach(workspaceState.tabs) { tab in
                        let isActive = (tab.id == workspaceState.activeTabID)

                        Button(action: {
                            workspaceState.selectTab(id: tab.id)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.isSplit ? "rectangle.split.2x1.fill" : "folder.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(isActive ? .accentColor : .secondary)

                                Text(tab.title)
                                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                                    .lineLimit(1)
                                    .frame(maxWidth: 160)

                                Button(action: {
                                    workspaceState.closeTab(id: tab.id)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.secondary)
                                        .padding(3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(isActive ? Color(nsColor: .controlBackgroundColor).opacity(0.9) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: {
                        workspaceState.newTab()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .help("New Tab (⌘T)")
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 22)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.22).opacity(0.65))
        )
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .enableInjection()
    }
}
