import SwiftUI
import AppKit

public struct IconsGridView: View {
    @Bindable var navigationState: NavigationState
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
                columns: [GridItem(.adaptive(minimum: navigationState.iconSize, maximum: navigationState.iconSize + 40), spacing: 16)],
                spacing: 16
            ) {
                ForEach(navigationState.filteredAndSortedItems) { item in
                    let isSelected = navigationState.selectedItemIDs.contains(item.id)
                    IconGridItemView(
                        item: item,
                        iconSize: navigationState.iconSize,
                        isSelected: isSelected
                    )
                    .contentShape(Rectangle())
                    .draggable(item.url)
                    .onTapGesture {
                        navigationState.selectedItemIDs = [item.id]
                    }
                    .onTapGesture(count: 2) {
                        onActivate(item)
                    }
                    .contextMenu {
                        contextMenuBuilder(item)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct IconGridItemView: View {
    let item: FileItem
    let iconSize: CGFloat
    let isSelected: Bool

    @State private var thumbnailImage: NSImage?

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let thumb = thumbnailImage {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: item.systemIconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(item.isDirectory ? .accentColor : .primary)
                }
            }
            .frame(width: iconSize * 0.6, height: iconSize * 0.6)
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            Text(item.name)
                .font(.system(size: 11))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
        }
        .frame(width: iconSize + 20, height: iconSize + 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
        .task(id: item.url) {
            let thumb = await ThumbnailService.shared.thumbnail(
                for: item.url,
                size: CGSize(width: iconSize * 2, height: iconSize * 2)
            )
            self.thumbnailImage = thumb
        }
    }
}
