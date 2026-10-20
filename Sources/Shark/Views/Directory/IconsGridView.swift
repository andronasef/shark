import SwiftUI
import AppKit

public struct IconsGridView: View {
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let onActivate: (FileItem) -> Void
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
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 96, maximum: 112), spacing: 20)],
                spacing: 24
            ) {
                ForEach(navigationState.filteredAndSortedItems) { item in
                    let isSelected = navigationState.selectedItemIDs.contains(item.id)
                    IconGridItemView(
                        item: item,
                        iconSize: 76,
                        isSelected: isSelected,
                        navigationState: navigationState
                    )
                    .contentShape(Rectangle())
                    .draggable(item.url)
                    .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
                    .onTapGesture {
                        navigationState.selectedItemIDs = [item.id]
                    }
                    .onTapGesture(count: 2) {
                        onActivate(item)
                    }
                    .onMiddleClick {
                        if item.isNavigableDirectory {
                            workspace?.open(item.url, from: navigationState, newTab: true)
                        }
                    }
                    .contextMenu {
                        contextMenuBuilder(item)
                    }
                }
            }
            .padding(20)
        }
        .onTapGesture {
            // Clicking empty canvas clears selection
            navigationState.selectedItemIDs.removeAll()
            navigationState.cancelRenaming()
        }
        .enableInjection()
    }
}

private struct IconGridItemView: View {
    let item: FileItem
    let iconSize: CGFloat
    let isSelected: Bool
    @Bindable var navigationState: NavigationState

    @State private var thumbnail: NSImage? = nil

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                } else {
                    Image(systemName: item.systemIconName)
                        .font(.system(size: iconSize * 0.7))
                        .foregroundColor(item.isDirectory ? .accentColor : .secondary)
                        .frame(width: iconSize, height: iconSize)
                }
            }
            .frame(width: iconSize, height: iconSize)

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
                .frame(width: 90, height: 20)
            } else {
                Text(item.name)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )
            }
        }
        .frame(width: max(iconSize + 16, 96))
        .task {
            if !item.isDirectory {
                thumbnail = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width: iconSize * 2, height: iconSize * 2))
            }
        }
    }
}
