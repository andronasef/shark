import SwiftUI

public struct TabStripView: View {
    let workspace: WorkspaceState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draggedTabID: UUID?
    @State private var dropTargetID: UUID?
    @State private var dropBefore: Bool = true
    @State private var isShowingSaveGroupAlert: Bool = false
    @State private var newGroupName: String = ""

    public init(workspace: WorkspaceState) {
        self.workspace = workspace
    }

    public var body: some View {
        GeometryReader { geo in
            let pinnedCount = workspace.pinnedCount
            let unpinnedCount = workspace.unpinnedTabs.count
            let pinnedWidth = CGFloat(pinnedCount * 40 + max(0, pinnedCount - 1) * 3)
            let groupSpacing: CGFloat = pinnedCount > 0 ? 6 : 0
            let available = max(0, geo.size.width - 34 - pinnedWidth - groupSpacing)
            let tabSpacing = CGFloat(max(0, unpinnedCount - 1)) * 3
            let width = max(120, (available - tabSpacing) / CGFloat(max(1, unpinnedCount)))

            HStack(spacing: 6) {
                if pinnedCount > 0 {
                    HStack(spacing: 3) {
                        ForEach(workspace.pinnedTabs) { tab in
                            tabView(tab, width: 40)
                        }
                    }
                }
                if unpinnedCount > 0 {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                ForEach(workspace.unpinnedTabs) { tab in
                                    tabView(tab, width: width)
                                }
                            }
                        }
                        .background(Capsule().fill(Color.primary.opacity(0.035)))
                        .onChange(of: workspace.activeTabID) { _, newID in
                            if reduceMotion {
                                proxy.scrollTo(newID, anchor: .center)
                            } else {
                                withAnimation(tabAnimation) {
                                    proxy.scrollTo(newID, anchor: .center)
                                }
                            }
                        }
                    }
                } else {
                    Spacer(minLength: 0)
                }

                Button { workspace.newTab(placement: .end) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .regular))
                        .frame(width: 28, height: 28)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .finderGlass()
                .help("New Tab (⌘T); right-click for Tab Groups")
                .accessibilityLabel("New Tab")
                .contextMenu { tabGroupCommands }
            }
            .finderGlassContainer()
            .animation(reduceMotion ? nil : tabAnimation, value: workspace.tabs.map(\.id))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .frame(height: 34)
        .onTabScroll { steps in
            for _ in 0..<abs(steps) { steps > 0 ? workspace.nextTab() : workspace.previousTab() }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 0.5)
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

    private func tabView(_ tab: WorkspaceTab, width: CGFloat) -> some View {
        TabItemView(
            tab: tab,
            width: width,
            isActive: tab.id == workspace.activeTabID,
            workspace: workspace,
            draggedTabID: $draggedTabID,
            dropTargetID: $dropTargetID,
            dropBefore: $dropBefore
        )
        .id(tab.id)
        .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.96)))
    }

    private var tabAnimation: Animation {
        .timingCurve(0.23, 1, 0.32, 1, duration: 0.2)
    }

    @ViewBuilder
    private var tabGroupCommands: some View {
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
    }

}
