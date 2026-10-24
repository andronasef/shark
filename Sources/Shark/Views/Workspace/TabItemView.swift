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
        L10n.text(rawValue.capitalized)
    }
}

public struct TabDropDelegate: DropDelegate {
    let targetTab: WorkspaceTab
    let workspace: WorkspaceState
    let targetWidth: CGFloat
    @Binding var draggedTabID: UUID?
    @Binding var dropTargetID: UUID?
    @Binding var dropBefore: Bool

    public init(
        targetTab: WorkspaceTab,
        workspace: WorkspaceState,
        draggedTabID: Binding<UUID?>,
        dropTargetID: Binding<UUID?>,
        dropBefore: Binding<Bool>,
        targetWidth: CGFloat = 120
    ) {
        self.targetWidth = targetWidth
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
        let isLeading = info.location.x < targetWidth / 2
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
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            if MouseSetting.tabDoubleClickPin.isEnabled { workspace.togglePin(id: tab.id) }
        })
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
                dropBefore: $dropBefore,
                targetWidth: tab.isPinned ? 40 : (width ?? 120)
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
        .frame(width: 40, height: 28)
        .finderGlass(isSelected: isActive, interactive: false)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 0.5)
        }
    }

    // MARK: - Unpinned Tab

    private var unpinnedTabBody: some View {
        HStack(spacing: 0) {
            // Leading Close Slot (20pt)
            ZStack {
                if isHovered || isCloseHovered {
                    Button {
                        workspace.closeTab(id: tab.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(isCloseHovered ? Color.primary : Color.secondary)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(isCloseHovered ? Color.primary.opacity(0.12) : Color.clear)
                            )
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .onHover { isCloseHovered = $0 }
                }
            }
            .frame(width: 20, height: 20)
            .padding(.leading, 8)

            Spacer(minLength: 4)

            // Centered Group
            HStack(spacing: 4) {
                if let tabColor = tab.color {
                    Circle()
                        .fill(tabColor.swiftUIColor)
                        .frame(width: 8, height: 8)
                }

                Text(tab.title)
                    .font(.system(size: 12, weight: isActive ? .semibold : .regular))
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

            // Trailing Balance Slot (20pt) to optically center title
            Color.clear
                .frame(width: 20, height: 20)
                .padding(.trailing, 8)
        }
        .frame(width: width, height: 28)
        .finderGlass(isSelected: true, interactive: false, enabled: isActive)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var tabContextMenu: some View {
        Button(L10n.text("New Tab"), systemImage: "plus.square") {
            workspace.newTab(placement: .afterActive)
        }

        Button(L10n.text("Duplicate Tab"), systemImage: "plus.square.on.square") {
            workspace.duplicateTab(id: tab.id)
        }

        Button(tab.isPinned ? L10n.text("Unpin Tab") : L10n.text("Pin Tab"), systemImage: tab.isPinned ? "pin.slash" : "pin") {
            workspace.togglePin(id: tab.id)
        }

        Button(tab.isLocked ? L10n.text("Unlock Tab") : L10n.text("Lock Tab"), systemImage: tab.isLocked ? "lock.open" : "lock") {
            workspace.toggleLock(id: tab.id)
        }

        Menu(L10n.text("Colour"), systemImage: "paintpalette") {
            Button(L10n.text("None")) {
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

        Button(L10n.text("Copy Path"), systemImage: "link") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(tab.activeNavigationState.currentURL.path, forType: .string)
        }

        Divider()

        Button(L10n.text("Close Tab"), systemImage: "xmark") {
            workspace.closeTab(id: tab.id)
        }

        Button(L10n.text("Close Other Tabs"), systemImage: "xmark.square") {
            workspace.closeOtherTabs(id: tab.id)
        }

        Button(L10n.text("Close Tabs to the Right"), systemImage: "arrow.right.to.line") {
            workspace.closeTabsToRight(id: tab.id)
        }

        Button(L10n.text("Reopen Closed Tab"), systemImage: "arrow.uturn.backward") {
            workspace.reopenClosedTab()
        }
        .disabled(workspace.closedTabs.isEmpty)
    }
}
