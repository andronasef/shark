import SwiftUI
import AppKit

extension TabColor {
    public var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .gray: return .gray
        }
    }

    public var displayName: String {
        rawValue.capitalized
    }
}

public struct TabDropDelegate: DropDelegate {
    let targetTab: WorkspaceTab
    let workspace: WorkspaceState
    @Binding var draggedTabID: UUID?
    @Binding var dropTargetID: UUID?
    @Binding var dropBefore: Bool

    public init(
        targetTab: WorkspaceTab,
        workspace: WorkspaceState,
        draggedTabID: Binding<UUID?>,
        dropTargetID: Binding<UUID?>,
        dropBefore: Binding<Bool>
    ) {
        self.targetTab = targetTab
        self.workspace = workspace
        self._draggedTabID = draggedTabID
        self._dropTargetID = dropTargetID
        self._dropBefore = dropBefore
    }

    public func dropEntered(info: DropInfo) {
        dropTargetID = targetTab.id
    }

    public func dropUpdated(info: DropInfo) -> DropProposal? {
        let isLeading = info.location.x < 60
        dropBefore = isLeading
        return DropProposal(operation: .move)
    }

    public func dropExited(info: DropInfo) {
        if dropTargetID == targetTab.id {
            dropTargetID = nil
        }
    }

    public func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedTabID = nil
            dropTargetID = nil
        }
        guard let sourceID = draggedTabID,
              let targetIndex = workspace.tabs.firstIndex(where: { $0.id == targetTab.id }) else {
            return false
        }

        let destinationIndex = dropBefore ? targetIndex : targetIndex + 1
        withAnimation(.easeOut(duration: 0.15)) {
            workspace.moveTab(id: sourceID, to: destinationIndex)
        }
        return true
    }
}

public struct TabItemView: View {
    let tab: WorkspaceTab
    let width: CGFloat?
    let isActive: Bool
    let workspace: WorkspaceState
    @Binding var draggedTabID: UUID?
    @Binding var dropTargetID: UUID?
    @Binding var dropBefore: Bool

    @State private var isHovered = false
    @State private var isCloseHovered = false

    public init(
        tab: WorkspaceTab,
        width: CGFloat? = nil,
        isActive: Bool,
        workspace: WorkspaceState,
        draggedTabID: Binding<UUID?>,
        dropTargetID: Binding<UUID?>,
        dropBefore: Binding<Bool>
    ) {
        self.tab = tab
        self.width = width
        self.isActive = isActive
        self.workspace = workspace
        self._draggedTabID = draggedTabID
        self._dropTargetID = dropTargetID
        self._dropBefore = dropBefore
    }

    private var folderIcon: NSImage {
        let path = tab.activeNavigationState.currentURL.path
        return NSWorkspace.shared.icon(forFile: path)
    }

    public var body: some View {
        Group {
            if tab.isPinned {
                pinnedTabBody
            } else {
                unpinnedTabBody
            }
        }
        .frame(height: 28)
        .contentShape(Rectangle())
        .onTapGesture {
            workspace.selectTab(id: tab.id)
        }
        .onMiddleClick {
            workspace.closeTab(id: tab.id)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .help(tab.tooltipText)
        .contextMenu {
            tabContextMenu
        }
        .onDrag {
            draggedTabID = tab.id
            return NSItemProvider(object: tab.id.uuidString as NSString)
        }
        .onDrop(
            of: [.text, .plainText],
            delegate: TabDropDelegate(
                targetTab: tab,
                workspace: workspace,
                draggedTabID: $draggedTabID,
                dropTargetID: $dropTargetID,
                dropBefore: $dropBefore
            )
        )
        .overlay(alignment: .leading) {
            if dropTargetID == tab.id && dropBefore {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2)
            }
        }
        .overlay(alignment: .trailing) {
            if dropTargetID == tab.id && !dropBefore {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2)
            }
        }
    }

    // MARK: - Pinned Tab

    private var pinnedTabBody: some View {
        ZStack {
            Rectangle()
                .fill(isActive ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor))

            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: folderIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)

                if let tabColor = tab.color {
                    Circle()
                        .fill(tabColor.swiftUIColor)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color(nsColor: .controlBackgroundColor), lineWidth: 1)
                        )
                        .offset(x: 4, y: 4)
                }
            }
        }
        .frame(width: 40)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 0.5)
        }
    }

    // MARK: - Unpinned Tab

    private var unpinnedTabBody: some View {
        HStack(spacing: 0) {
            // Leading Close Slot (16pt)
            ZStack {
                if isHovered || isCloseHovered {
                    Button {
                        workspace.closeTab(id: tab.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isCloseHovered ? Color.primary : Color.secondary)
                            .frame(width: 16, height: 16)
                            .background(
                                Circle()
                                    .fill(isCloseHovered ? Color.primary.opacity(0.12) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { isCloseHovered = $0 }
                }
            }
            .frame(width: 16, height: 16)
            .padding(.leading, 8)

            Spacer(minLength: 4)

            // Centered Group
            HStack(spacing: 4) {
                if let tabColor = tab.color {
                    Circle()
                        .fill(tabColor.swiftUIColor)
                        .frame(width: 8, height: 8)
                }

                Image(nsImage: folderIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)

                Text(tab.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if tab.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            // Trailing Balance Slot (16pt) to optically center title
            Color.clear
                .frame(width: 16, height: 16)
                .padding(.trailing, 8)
        }
        .frame(width: width)
        .background(isActive ? Color(nsColor: .windowBackgroundColor) : Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 0.5)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var tabContextMenu: some View {
        Button("New Tab") {
            workspace.newTab(placement: .afterActive)
        }

        Button("Duplicate Tab") {
            workspace.duplicateTab(id: tab.id)
        }

        Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") {
            workspace.togglePin(id: tab.id)
        }

        Button(tab.isLocked ? "Unlock Tab" : "Lock Tab") {
            workspace.toggleLock(id: tab.id)
        }

        Menu("Colour") {
            Button("None") {
                workspace.setColor(nil, for: tab.id)
            }
            Divider()
            ForEach(TabColor.allCases, id: \.self) { color in
                Button {
                    workspace.setColor(color, for: tab.id)
                } label: {
                    HStack {
                        Text(color.displayName)
                        if tab.color == color {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Divider()

        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(tab.activeNavigationState.currentURL.path, forType: .string)
        }

        Divider()

        Button("Close Tab") {
            workspace.closeTab(id: tab.id)
        }

        Button("Close Other Tabs") {
            workspace.closeOtherTabs(id: tab.id)
        }

        Button("Close Tabs to the Right") {
            workspace.closeTabsToRight(id: tab.id)
        }

        Button("Reopen Closed Tab") {
            workspace.reopenClosedTab()
        }
        .disabled(workspace.closedTabs.isEmpty)
    }
}
