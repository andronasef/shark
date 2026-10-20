import SwiftUI

public struct TabStripView: View {
    let workspace: WorkspaceState
    @State private var draggedTabID: UUID?
    @State private var dropTargetID: UUID?
    @State private var dropBefore: Bool = true

    public init(workspace: WorkspaceState) {
        self.workspace = workspace
    }

    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let pinnedWidth = CGFloat(workspace.pinnedCount * 40)
            let plusWidth: CGFloat = 28.0
            let availableForTabs = max(0, totalWidth - pinnedWidth - plusWidth)
            let unpinnedCount = max(1, workspace.unpinnedTabs.count)
            let unpinnedWidth = min(260.0, max(120.0, availableForTabs / CGFloat(unpinnedCount)))

            HStack(spacing: 0) {
                // Fixed pinned group
                HStack(spacing: 0) {
                    ForEach(workspace.pinnedTabs) { tab in
                        TabItemView(
                            tab: tab,
                            width: 40,
                            isActive: tab.id == workspace.activeTabID,
                            workspace: workspace,
                            draggedTabID: $draggedTabID,
                            dropTargetID: $dropTargetID,
                            dropBefore: $dropBefore
                        )
                        .id(tab.id)
                    }
                }

                // Scrollable unpinned tabs
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(workspace.unpinnedTabs) { tab in
                                TabItemView(
                                    tab: tab,
                                    width: unpinnedWidth,
                                    isActive: tab.id == workspace.activeTabID,
                                    workspace: workspace,
                                    draggedTabID: $draggedTabID,
                                    dropTargetID: $dropTargetID,
                                    dropBefore: $dropBefore
                                )
                                .id(tab.id)
                            }
                        }
                    }
                    .onChange(of: workspace.activeTabID) { _, newID in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(newID, anchor: .center)
                        }
                    }
                }

                // Empty strip area: double-click creates new tab
                Color.clear
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        workspace.newTab(placement: .end)
                    }

                // Fixed "+" button
                Button {
                    workspace.newTab(placement: .end)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("New Tab (⌘T)")
            }
        }
        .frame(height: 28)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 0.5)
        }
    }
}
