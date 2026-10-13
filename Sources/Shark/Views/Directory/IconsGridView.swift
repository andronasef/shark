import SwiftUI
import AppKit
import Inject

public struct IconsGridView: View {
    @ObserveInjection var inject
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
                columns: [GridItem(.adaptive(minimum: 96, maximum: 112), spacing: 20)],
                spacing: 24
            ) {
                ForEach(navigationState.filteredAndSortedItems) { item in
                    let isSelected = navigationState.selectedItemIDs.contains(item.id)
                    IconGridItemView(
                        item: item,
                        iconSize: 76,
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
            .padding(20)
        }
        .onTapGesture {
            // Clicking empty canvas clears selection
            navigationState.selectedItemIDs.removeAll()
        }
        .enableInjection()
    }
}

private struct IconGridItemView: View {
    let item: FileItem
    let iconSize: CGFloat
    let isSelected: Bool

    @State private var thumbnailImage: NSImage?

    var body: some View {
        VStack(spacing: 5) {
            // Icon presentation matching native macOS Finder
            Group {
                if let thumb = thumbnailImage {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: iconSize, height: iconSize)
            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)

            // Finder-authentic selection label
            Text(item.name)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color(nsColor: .controlAccentColor) : Color.clear)
                )
        }
        .frame(width: 96, alignment: .top)
        .contentShape(Rectangle())
        .task(id: item.url) {
            let thumb = await ThumbnailService.shared.thumbnail(
                for: item.url,
                size: CGSize(width: iconSize * 2, height: iconSize * 2)
            )
            self.thumbnailImage = thumb
        }
    }
}
