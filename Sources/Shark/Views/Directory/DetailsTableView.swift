import SwiftUI
import AppKit

public struct DetailsTableView: View {
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let onActivate: (FileItem) -> Void
    @State private var lastClickedURL: URL? = nil
    @State private var lastClickTime: TimeInterval = 0
    let contextMenuBuilder: (FileItem) -> AnyView

    public init(
        navigationState: NavigationState,
        onActivate: @escaping (FileItem) -> Void,
        @ViewBuilder contextMenu: @escaping (FileItem) -> some View
    ) {
        self.navigationState = navigationState
        self.onActivate = onActivate
        self.contextMenuBuilder = { AnyView(contextMenu($0)) }
    }

    public var body: some View {
        Table(
            navigationState.filteredAndSortedItems,
            selection: $navigationState.selectedItemIDs,
            sortOrder: Binding(
                get: { [keyPathComparator] },
                set: { newOrder in
                    handleSortChange(newOrder)
                }
            )
        ) {
            TableColumn("Name", value: \.name) { item in
                HoverReveal { hovering in
                    HStack(spacing: 8) {
                        FileItemIconView(item: item, size: 18)
                            .frame(width: 18, height: 18)

                        if navigationState.renamingItemURL == item.url {
                            InlineRenameField(
                                initialName: item.name,
                                onCommit: { newName in
                                    Task { await navigationState.commitRename(url: item.url, newName: newName) }
                                },
                                onCancel: {
                                    navigationState.cancelRenaming()
                                }
                            )
                            .frame(height: 20)
                        } else {
                            Text(item.name)
                                .lineLimit(1)
                        }

                        SubfolderTip(item: item, isHovering: hovering, size: 20) { targetURL, inNewTab in
                            if inNewTab, let workspace {
                                workspace.open(targetURL, from: navigationState, newTab: true)
                            } else {
                                navigationState.navigateTo(targetURL)
                            }
                        }
                    }
                }
                .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
                .contentShape(Rectangle())
                .fileDragSource(item: item, navigationState: navigationState)
                .dropDestination(for: URL.self) { droppedURLs, _ in
                    guard item.isNavigableDirectory else { return false }
                    let modifiers = NSEvent.modifierFlags
                    Task { await navigationState.drop(droppedURLs, into: item.url, modifiers: modifiers) }
                    return true
                }
                .onTapGesture {
                    let now = Date().timeIntervalSince1970
                    if lastClickedURL == item.url && (now - lastClickTime < 0.4) {
                        lastClickedURL = nil
                        lastClickTime = 0
                        onActivate(item)
                        return
                    }
                    lastClickedURL = item.url
                    lastClickTime = now
                    navigationState.click(
                        item,
                        command: NSEvent.modifierFlags.contains(.command),
                        shift: NSEvent.modifierFlags.contains(.shift)
                    )
                }
                .onRightClickSelect {
                    if !navigationState.selectedItemIDs.contains(item.id) {
                        navigationState.selectedItemIDs = [item.id]
                    }
                }
                .onMiddleClick {
                    if item.isNavigableDirectory {
                        workspace?.open(item.url, from: navigationState, newTab: true)
                    }
                }
                .contextMenu {
                    contextMenuBuilder(item)
                }
                .fileHoverPreview(item, isRenaming: navigationState.renamingItemURL == item.url)
            }
            .width(min: 200, ideal: 320)

            TableColumn("Size", value: \.fileSize) { item in
                Group {
                    if item.isDirectory {
                        if let size = FolderSizeCalculator.shared.size(for: item.url) {
                            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        } else if FolderSizeCalculator.shared.isCalculating(url: item.url) {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Text("--")
                        }
                    } else {
                        Text(item.formattedSize)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Date Modified", value: \.dateModified) { item in
                Text(item.dateModified.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
                    .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
            }
            .width(min: 130, ideal: 160)

            TableColumn("Kind", value: \.kindDescription) { item in
                Text(item.kindDescription)
                    .foregroundColor(.secondary)
                    .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
            }
            .width(min: 120, ideal: 150)
        }
        .onTableMarginDoubleClick { navigationState.goUp() }
    }

    private var keyPathComparator: KeyPathComparator<FileItem> {
        let order: SortOrder = navigationState.sortAscending ? .forward : .reverse
        switch navigationState.sortField {
        case .name:
            return KeyPathComparator(\FileItem.name, order: order)
        case .size:
            return KeyPathComparator(\FileItem.fileSize, order: order)
        case .dateModified:
            return KeyPathComparator(\FileItem.dateModified, order: order)
        case .kind:
            return KeyPathComparator(\FileItem.kindDescription, order: order)
        case .permissions:
            return KeyPathComparator(\FileItem.posixPermissions, order: order)
        }
    }

    private func handleSortChange(_ newOrder: [KeyPathComparator<FileItem>]) {
        guard let primary = newOrder.first else { return }
        navigationState.sortAscending = (primary.order == .forward)

        if primary.keyPath == \FileItem.name {
            navigationState.sortField = .name
        } else if primary.keyPath == \FileItem.fileSize {
            navigationState.sortField = .size
        } else if primary.keyPath == \FileItem.dateModified {
            navigationState.sortField = .dateModified
        } else if primary.keyPath == \FileItem.kindDescription {
            navigationState.sortField = .kind
        } else if primary.keyPath == \FileItem.posixPermissions {
            navigationState.sortField = .permissions
        }
    }
}
