import AppKit
import SwiftUI

/// The sidebar's Folder Tree: an expandable list of folders like File Explorer's navigation pane.
/// Clicking a row opens the folder; the arrow only expands or collapses it.
struct FolderTreeRows: View {
    let roots: [FolderTreeRoot]
    @Bindable var navigationState: NavigationState
    let tree: FolderTreeModel
    let favoritesStore: SidebarFavoritesStore
    @FocusState.Binding var focus: String?
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovered: String?
    @State private var dropTarget: String?

    private var rows: [FolderTreeModel.Row] { tree.rows(for: roots) }
    private var showHidden: Bool { navigationState.showHiddenFiles }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows) { row in treeRow(row).id(row.id) }
            }
            .task(id: navigationState.currentURL) {
                await tree.reveal(navigationState.currentURL, roots: roots.map(\.url), showHidden: showHidden)
                guard !Task.isCancelled else { return }
                let id = FolderTree.key(navigationState.currentURL)
                if rows.contains(where: { $0.id == id }) {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) { proxy.scrollTo(id) }
                }
            }
            .task(id: showHidden) { await tree.reloadExpanded(showHidden: showHidden) }
            // New or removed subfolders in the folder being browsed.
            .onChange(of: navigationState.items.count) {
                let url = navigationState.currentURL
                if tree.isExpanded(url) { Task { await tree.load(url, showHidden: showHidden) } }
            }
        }
    }

    private func treeRow(_ row: FolderTreeModel.Row) -> some View {
        let rowID = "Tree:" + row.id
        let isSelected = FolderTree.key(navigationState.currentURL) == row.id
        let activate: () -> Void = {
            focus = rowID
            if let workspace { workspace.open(row.url, from: navigationState, newTab: NSEvent.modifierFlags.contains(.command)) }
            else { navigationState.navigateTo(row.url) }
        }
        let toggle: () -> Void = { Task { await tree.toggle(row.url, showHidden: showHidden) } }
        return rowContent(row, rowID: rowID, isSelected: isSelected, activate: activate, toggle: toggle)
            .focusable()
            .focusEffectDisabled()
            .focused($focus, equals: rowID)
            .onHover { hovered = $0 ? rowID : nil }
            .onKeyPress(.return) { activate(); return .handled }
            .onKeyPress(.space) { activate(); return .handled }
            .onKeyPress(.rightArrow) { moveRight(row, toggle: toggle); return .handled }
            .onKeyPress(.leftArrow) { moveLeft(row, toggle: toggle); return .handled }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityValue(accessibilityState(row))
            .help(row.url.path)
            .onMiddleClick { workspace?.open(row.url, from: navigationState, newTab: true) }
            .contextMenu { rowMenu(row) }
            .dropDestination(for: URL.self) { urls, _ in
                let modifiers = NSEvent.modifierFlags
                let destination = row.url
                Task { await navigationState.drop(urls, into: destination, modifiers: modifiers) }
                return true
            } isTargeted: { targeted in
                dropTarget = targeted ? rowID : nil
            }
    }

    private func rowContent(_ row: FolderTreeModel.Row, rowID: String, isSelected: Bool,
                            activate: @escaping () -> Void, toggle: @escaping () -> Void) -> some View {
        let tint = Color.primary.opacity(isSelected ? 0.09 : (hovered == rowID ? 0.045 : 0))
        return HStack(spacing: 2) {
            Color.clear.frame(width: CGFloat(row.depth) * 12, height: 1)
            Button(action: toggle) { chevron(row) }
                .buttonStyle(.plain)
                .disabled(!row.canExpand)
                .accessibilityLabel(row.isExpanded ? L10n.text("Collapse") : L10n.text("Expand"))
                .accessibilityHidden(!row.canExpand)
            Button(action: activate) { label(row, isSelected: isSelected) }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(tint))
        .overlay { highlight(rowID) }
    }

    private func chevron(_ row: FolderTreeModel.Row) -> some View {
        let angle: Double = row.isExpanded ? (layoutIsLTR ? 90 : -90) : 0
        return Image(systemName: "chevron.forward")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(angle))
            .frame(width: 18, height: 26)
            .contentShape(Rectangle())
            .opacity(row.canExpand ? 1 : 0)
    }

    private func label(_ row: FolderTreeModel.Row, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: row.icon)
                .font(.system(size: 14))
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(row.name)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .frame(height: 28)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func highlight(_ rowID: String) -> some View {
        if dropTarget == rowID {
            RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 2)
                .background(Color.accentColor.opacity(0.08))
        }
        if focus == rowID { RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 1.5) }
    }

    @ViewBuilder
    private func rowMenu(_ row: FolderTreeModel.Row) -> some View {
        Button(L10n.text("Open in New Tab"), systemImage: "plus.rectangle.on.rectangle") {
            workspace?.open(row.url, from: navigationState, newTab: true)
        }
        Button(L10n.text("Add to Favorites"), systemImage: "star") {
            _ = favoritesStore.insert([row.url], at: favoritesStore.items.count)
        }
        Button(L10n.text("Show in Finder"), systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting([row.url]) }
        Button(L10n.text("Refresh"), systemImage: "arrow.clockwise") { Task { await tree.load(row.url, showHidden: showHidden) } }
    }

    private func accessibilityState(_ row: FolderTreeModel.Row) -> String {
        guard row.canExpand else { return "" }
        return row.isExpanded ? L10n.text("Expanded") : L10n.text("Collapsed")
    }

    private func moveRight(_ row: FolderTreeModel.Row, toggle: () -> Void) {
        if row.canExpand && !row.isExpanded { toggle() }
        else if row.isExpanded, let child = firstChild(of: row) { focus = "Tree:" + child.id }
    }

    private func moveLeft(_ row: FolderTreeModel.Row, toggle: () -> Void) {
        if row.isExpanded { toggle() }
        else if let parent = parent(of: row) { focus = "Tree:" + parent.id }
        else { focus = "Folders:header" }
    }

    private var layoutIsLTR: Bool { AppLocalization.layoutDirection == .leftToRight }

    private func firstChild(of row: FolderTreeModel.Row) -> FolderTreeModel.Row? {
        guard let index = rows.firstIndex(where: { $0.id == row.id }), rows.indices.contains(index + 1),
              rows[index + 1].depth == row.depth + 1 else { return nil }
        return rows[index + 1]
    }

    private func parent(of row: FolderTreeModel.Row) -> FolderTreeModel.Row? {
        guard row.depth > 0, let index = rows.firstIndex(where: { $0.id == row.id }) else { return nil }
        return rows[..<index].last { $0.depth == row.depth - 1 }
    }
}
