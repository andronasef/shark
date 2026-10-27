import SwiftUI
import AppKit

@Observable
@MainActor
private final class MarqueeState {
    var rect: CGRect? = nil
    var isDragging = false
    var dragStartPoint: CGPoint? = nil
    var initialSelection: Set<URL> = []
    var itemFrames: [URL: CGRect] = [:]
}

private struct MarqueeBoxView: View {
    let marquee: MarqueeState

    var body: some View {
        if let rect = marquee.rect, rect.width > 2 || rect.height > 2 {
            Rectangle()
                .fill(Color.accentColor.opacity(0.18))
                .overlay(
                    Rectangle()
                        .stroke(Color.accentColor.opacity(0.65), lineWidth: 1)
                )
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
                .allowsHitTesting(false)
        }
    }
}

public struct IconsGridView: View {
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let onActivate: (FileItem) -> Void
    let contextMenuBuilder: (FileItem) -> AnyView

    // Rubberband marquee selection state
    @State private var marqueeState = MarqueeState()

    // Track click timestamp and target for double-click detection
    @State private var lastClickedURL: URL? = nil
    @State private var lastClickTime: TimeInterval = 0

    public init(
        navigationState: NavigationState,
        onActivate: @escaping (FileItem) -> Void,
        @ViewBuilder contextMenu: @escaping (FileItem) -> some View
    ) {
        self.navigationState = navigationState
        self.onActivate = onActivate
        self.contextMenuBuilder = { item in AnyView(DeferredMenu { contextMenu(item) }) }
    }

    public var body: some View {
        GeometryReader { containerGeo in
            ScrollView {
                let currentIconSize = navigationState.iconSize
                let cellMinWidth = max(currentIconSize + 28, 96)
                let cellMaxWidth = cellMinWidth + 32

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: cellMinWidth, maximum: cellMaxWidth), spacing: 20)],
                    spacing: 24
                ) {
                    ForEach(navigationState.filteredAndSortedItems) { item in
                        let isSelected = navigationState.selectedItemIDs.contains(item.id)
                        IconGridItemView(
                            item: item,
                            iconSize: currentIconSize,
                            isSelected: isSelected,
                            navigationState: navigationState,
                            onSubfolderNavigate: { targetURL, inNewTab in
                                if inNewTab, let workspace {
                                    workspace.open(targetURL, from: navigationState, newTab: true)
                                } else {
                                    navigationState.navigateTo(targetURL)
                                }
                            }
                        )
                        .background {
                            // Frames are only needed during a marquee drag; reporting them on every
                            // scroll frame merged a URL-keyed dictionary across all visible cells.
                            if marqueeState.isDragging {
                                GeometryReader { itemGeo in
                                    Color.clear
                                        .preference(
                                            key: ItemFramePreferenceKey.self,
                                            value: [item.url: itemGeo.frame(in: .named("IconGridCoordinateSpace"))]
                                        )
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .fileDragSource(item: item, navigationState: navigationState)
                        .dropDestination(for: URL.self) { droppedURLs, _ in
                            guard item.isNavigableDirectory else { return false }
                            let modifiers = NSEvent.modifierFlags
                            Task { await navigationState.drop(droppedURLs, into: item.url, modifiers: modifiers) }
                            return true
                        }
                        .opacity(navigationState.isCut(item) ? 0.45 : 1.0)
                        .onTapGesture {
                            handleItemTap(item)
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
                        .fileItemAccessibility(item, isSelected: isSelected, isRenaming: navigationState.renamingItemURL == item.url) {
                            onActivate(item)
                        }
                    }
                }
                .padding(20)
                // One measured child: a ZStack around the lazy grid sized all items twice per scroll frame.
                .frame(maxWidth: .infinity, minHeight: containerGeo.size.height, alignment: .topLeading)
                .background {
                    // Empty background for canvas drag and canvas click
                    Color.clear
                        .contentShape(Rectangle())
                        .simultaneousGesture(TapGesture(count: 2).onEnded {
                            if MouseSetting.marginDoubleClickUp.isEnabled { navigationState.goUp() }
                        })
                        .onTapGesture {
                            let isShiftOrCmd = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                            if !isShiftOrCmd {
                                navigationState.selectedItemIDs.removeAll()
                            }
                            navigationState.cancelRenaming()
                        }
                        .gesture(
                            DragGesture(minimumDistance: 4, coordinateSpace: .named("IconGridCoordinateSpace"))
                                .onChanged { value in
                                    if marqueeState.dragStartPoint == nil {
                                        marqueeState.dragStartPoint = value.startLocation
                                        marqueeState.isDragging = true
                                        let isShiftOrCmd = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                                        marqueeState.initialSelection = isShiftOrCmd ? navigationState.selectedItemIDs : []
                                    }
                                    let start = marqueeState.dragStartPoint ?? value.startLocation
                                    let current = value.location
                                    let rect = CGRect(
                                        x: min(start.x, current.x),
                                        y: min(start.y, current.y),
                                        width: abs(current.x - start.x),
                                        height: abs(current.y - start.y)
                                    )
                                    marqueeState.rect = rect
                                    updateMarqueeSelection(rect: rect)
                                }
                                .onEnded { _ in
                                    marqueeState.dragStartPoint = nil
                                    marqueeState.rect = nil
                                    marqueeState.isDragging = false
                                    marqueeState.initialSelection = []
                                }
                        )
                }
                // Finder Rubberband Marquee Drag Selection Rectangle
                .overlay(alignment: .topLeading) { MarqueeBoxView(marquee: marqueeState) }
                .coordinateSpace(name: "IconGridCoordinateSpace")
                .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
                    marqueeState.itemFrames = frames
                }
                .onAppear {
                    updateGridColumnCount(width: containerGeo.size.width)
                }
                .onChange(of: containerGeo.size.width) {
                    updateGridColumnCount(width: containerGeo.size.width)
                }
                .onChange(of: navigationState.iconSize) {
                    updateGridColumnCount(width: containerGeo.size.width)
                }
            }
        }
        .enableInjection()
    }

    private func updateGridColumnCount(width: CGFloat) {
        let currentIconSize = navigationState.iconSize
        let cellMinWidth = max(currentIconSize + 28, 96)
        let availableWidth = max(0, width - 40)
        let colWidth = cellMinWidth + 20
        let cols = max(1, Int(availableWidth / colWidth))
        navigationState.gridColumnCount = cols
    }

    private func handleItemTap(_ item: FileItem) {
        let now = Date().timeIntervalSince1970
        let isDoubleTap = (lastClickedURL == item.url) && (now - lastClickTime < 0.4)

        if isDoubleTap {
            // Immediate folder / file open on double-click
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

    private func updateMarqueeSelection(rect: CGRect) {
        var newlySelected = marqueeState.initialSelection

        for (url, frame) in marqueeState.itemFrames {
            if rect.intersects(frame) {
                newlySelected.insert(url)
            } else if !marqueeState.initialSelection.contains(url) {
                newlySelected.remove(url)
            }
        }

        if newlySelected != navigationState.selectedItemIDs {
            navigationState.selectedItemIDs = newlySelected
        }
    }
}

private struct ItemFramePreferenceKey: PreferenceKey {
    static let defaultValue: [URL: CGRect] = [:]
    static func reduce(value: inout [URL: CGRect], nextValue: () -> [URL: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct IconGridItemView: View {
    let item: FileItem
    let iconSize: CGFloat
    let isSelected: Bool
    @Bindable var navigationState: NavigationState
    let onSubfolderNavigate: (URL, Bool) -> Void

    @State private var thumbnail: NSImage? = nil
    @Environment(\.displayScale) private var displayScale
    @State private var isHovering = false

    private var requestSize: CGFloat { ThumbnailService.requestDimension(iconSize) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let thumb = thumbnail, !item.isDirectory {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize, height: iconSize)
                        .cornerRadius(4)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                } else {
                    FileItemIconView(item: item, size: iconSize)
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
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.accentColor : Color.clear)
                    )
            }
        }
        .frame(width: max(iconSize + 28, 104))
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) {
            SubfolderTip(item: item, isHovering: isHovering, size: 26, onNavigate: onSubfolderNavigate)
                .padding(2)
        }
        // After the overlay, so the arrow is inside the hovered view. Before it, the arrow was a
        // sibling on top: reaching it ended the cell's hover, hid the arrow, restarted the hover,
        // and the arrow flickered.
        .onHover { isHovering = $0 }
        .task(id: "\(item.url.absoluteString)|\(item.dateModified)|\(item.fileSize)|\(item.isDirectory)|\(requestSize)|\(displayScale)") {
            if !item.isDirectory {
                guard let image = await ThumbnailService.shared.settledThumbnail(for: item.url, size: CGSize(width: requestSize, height: requestSize), scale: displayScale) else { return }
                thumbnail = image
            } else {
                thumbnail = nil
            }
        }
    }
}
