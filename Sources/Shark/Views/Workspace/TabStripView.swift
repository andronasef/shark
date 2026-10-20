import SwiftUI

public struct TabStripView: View {
    let workspace: WorkspaceState
    @State private var draggedTabID: UUID?
    @State private var dropTargetID: UUID?
    @State private var dropBefore: Bool = true
    @State private var isShowingGroupsMenu: Bool = false
    @State private var isShowingSaveGroupAlert: Bool = false
    @State private var newGroupName: String = ""

    public init(workspace: WorkspaceState) {
        self.workspace = workspace
    }

    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let pinnedWidth = CGFloat(workspace.pinnedCount * 40)
            let actionButtonsWidth: CGFloat = 64.0
            let availableForTabs = max(0, totalWidth - pinnedWidth - actionButtonsWidth)
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

                // Tab Groups Button (QT-05)
                Menu {
                    Button("Save Tabs as Group...") {
                        newGroupName = "Group \(TabGroupService.shared.groups.count + 1)"
                        isShowingSaveGroupAlert = true
                    }

                    if !TabGroupService.shared.groups.isEmpty {
                        Divider()
                        ForEach(TabGroupService.shared.groups) { group in
                            Menu(group.name) {
                                Button("Restore (Replace)") {
                                    TabGroupService.shared.restore(group: group, into: workspace, replace: true)
                                }
                                Button("Append Tabs") {
                                    TabGroupService.shared.restore(group: group, into: workspace, replace: false)
                                }
                                Divider()
                                Button("Delete Group", role: .destructive) {
                                    TabGroupService.shared.deleteGroup(id: group.id)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                        .frame(width: 24, height: 28)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .help("Tab Groups (QT-05)")

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
        .liquidGlassBackground(material: .headerView)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 0.5)
        }
        .sheet(isPresented: $isShowingSaveGroupAlert) {
            VStack(spacing: 16) {
                Text("Save Current Tabs as Group")
                    .font(.headline)

                TextField("Group Name", text: $newGroupName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)

                HStack {
                    Button("Cancel") {
                        isShowingSaveGroupAlert = false
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Save") {
                        if !newGroupName.trimmingCharacters(in: .whitespaces).isEmpty {
                            _ = TabGroupService.shared.saveGroup(name: newGroupName, tabs: workspace.tabs)
                        }
                        isShowingSaveGroupAlert = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 320)
        }
    }
}
