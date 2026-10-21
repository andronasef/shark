import SwiftUI
import AppKit

public struct IconsGridView: View {
    @Bindable var navigationState: NavigationState
    @Environment(WorkspaceState.self) private var workspace: WorkspaceState?
    let onActivate: (FileItem) -> Void
    let contextMenuBuilder: (FileItem) -> AnyView

    // Rubberband marquee selection state
    @State private var dragStart: CGPoint? = nil
    @State private var dragCurrent: CGPoint? = nil
    @State private var initialSelectionBeforeDrag: Set<URL> = []
    @State private var itemFrames: [URL: CGRect] = [:]

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
        self.contextMenuBuilder = { AnyView(contextMenu($0)) }
    }

    private var marqueeRect: CGRect? {
        guard let start = dragStart, let current = dragCurrent else { return nil }
        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    public var body: some View {
        GeometryReader { containerGeo in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Empty background for canvas drag and canvas click
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: containerGeo.size.height)
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
                                    if dragStart == nil {
                                        dragStart = value.startLocation
                                        let isShiftOrCmd = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                                        initialSelectionBeforeDrag = isShiftOrCmd ? navigationState.selectedItemIDs : []
                                    }
                                    dragCurrent = value.location

                                    if let rect = marqueeRect {
                                        updateMarqueeSelection(rect: rect)
                                    }
                                }
                                .onEnded { _ in
                                    dragStart = nil
                                    dragCurrent = nil
                                    initialSelectionBeforeDrag = []
                                }
                        )

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
                            .background(
                                GeometryReader { itemGeo in
                                    Color.clear
                                        .preference(
                                            key: ItemFramePreferenceKey.self,
                                            value: [item.url: itemGeo.frame(in: .named("IconGridCoordinateSpace"))]
                                        )
                                }
                            )
                            .contentShape(Rectangle())
                            .draggable(item.url)
                            .dropDestination(for: URL.self) { droppedURLs, _ in
                                guard item.isNavigableDirectory else { return false }
                                let isAltHeld = NSEvent.modifierFlags.contains(.option)
                                Task {
                                    if isAltHeld {
                                        try? await FileOperationsService.shared.copy(items: droppedURLs, to: item.url)
                                    } else {
                                        try? await FileOperationsService.shared.move(items: droppedURLs, to: item.url)
                                    }
                                    await navigationState.reloadCurrentDirectory()
                                }
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
                        }
                    }
                    .padding(20)

                    // Finder Rubberband Marquee Drag Selection Rectangle
                    if let rect = marqueeRect, rect.width > 2 || rect.height > 2 {
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
                .frame(maxWidth: .infinity, minHeight: containerGeo.size.height, alignment: .topLeading)
                .coordinateSpace(name: "IconGridCoordinateSpace")
                .onPreferenceChange(ItemFramePreferenceKey.self) { frames in
                    itemFrames = frames
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
        var newlySelected = initialSelectionBeforeDrag

        for (url, frame) in itemFrames {
            if rect.intersects(frame) {
                newlySelected.insert(url)
            } else if !initialSelectionBeforeDrag.contains(url) {
                newlySelected.remove(url)
            }
        }

        navigationState.selectedItemIDs = newlySelected
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
    @State private var isHovering = false

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
        .task {
            if !item.isDirectory {
                thumbnail = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width: iconSize * 2, height: iconSize * 2))
            }
        }
    }
}
