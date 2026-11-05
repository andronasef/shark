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
            ScrollViewReader { scrollProxy in
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
                                isRenaming: navigationState.renamingItemURL == item.url,
                                onCommitRename: { newName in
                                    Task { await navigationState.commitRename(url: item.url, newName: newName) }
                                },
                                onCancelRename: {
                                    navigationState.cancelRenaming()
                                },
                                onSubfolderNavigate: { targetURL, inNewTab in
                                    if inNewTab, let workspace {
                                        workspace.open(targetURL, from: navigationState, newTab: true)
                                    } else {
                                        navigationState.navigateTo(targetURL)
                                    }
                                }
                            )
                            .equatable()
                            .id(item.url)
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
                            let isShiftOrCmd = !NSEvent.clickModifiers.isDisjoint(with: [.shift, .command])
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
                                        let isShiftOrCmd = !NSEvent.clickModifiers.isDisjoint(with: [.shift, .command])
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
                                    updateMarqueeSelection(rect: rect, containerWidth: containerGeo.size.width)
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
                .onChange(of: navigationState.scrollToURL) { _, targetURL in
                    guard let targetURL else { return }
                    scrollProxy.scrollTo(targetURL, anchor: nil)
                }
                .background {
                    GridScrollSynchronizer(
                        targetURL: navigationState.scrollToURL,
                        items: navigationState.filteredAndSortedItems,
                        iconSize: navigationState.iconSize,
                        gridColumnCount: navigationState.gridColumnCount,
                        containerWidth: containerGeo.size.width,
                        containerHeight: containerGeo.size.height,
                        isDragging: marqueeState.isDragging,
                        onAutoScrollTick: { currentDocPoint in
                            handleAutoScrollMarquee(currentDocPoint: currentDocPoint, containerWidth: containerGeo.size.width)
                        },
                        onDragEnded: {
                            marqueeState.dragStartPoint = nil
                            marqueeState.rect = nil
                            marqueeState.isDragging = false
                            marqueeState.initialSelection = []
                        }
                    )
                }
            }
            }
        }
        .enableInjection()
    }

    private func updateGridColumnCount(width: CGFloat) {
        let currentIconSize = navigationState.iconSize
        let cellMinWidth = max(currentIconSize + 28, 96)
        let availableWidth = max(0, width - 40)
        let cols = max(1, Int((availableWidth + 20) / (cellMinWidth + 20)))
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
            command: NSEvent.clickModifiers.contains(.command),
            shift: NSEvent.clickModifiers.contains(.shift)
        )
    }

    private func handleAutoScrollMarquee(currentDocPoint: CGPoint, containerWidth: CGFloat) {
        guard marqueeState.isDragging, let start = marqueeState.dragStartPoint else { return }
        let rect = CGRect(
            x: min(start.x, currentDocPoint.x),
            y: min(start.y, currentDocPoint.y),
            width: abs(currentDocPoint.x - start.x),
            height: abs(currentDocPoint.y - start.y)
        )
        marqueeState.rect = rect
        updateMarqueeSelection(rect: rect, containerWidth: containerWidth)
    }

    private func updateMarqueeSelection(rect: CGRect, containerWidth: CGFloat) {
        let items = navigationState.filteredAndSortedItems
        guard !items.isEmpty else { return }

        let cols = max(1, navigationState.gridColumnCount)
        let currentIconSize = navigationState.iconSize
        let cellMinWidth = max(currentIconSize + 28, 96)
        let availableWidth = max(0, containerWidth - 40)
        let colWidth = max(cellMinWidth, (availableWidth - CGFloat(cols - 1) * 20) / CGFloat(cols))
        let colStride = colWidth + 20
        let itemHeight = currentIconSize + 58
        let rowStride = itemHeight + 24

        let minRow = max(0, Int((rect.minY - 20) / rowStride))
        let maxRow = max(0, Int((rect.maxY - 20) / rowStride))
        let minCol = max(0, min(cols - 1, Int((rect.minX - 20) / colStride)))
        let maxCol = max(0, min(cols - 1, Int((rect.maxX - 20) / colStride)))

        var activeDragSelection = Set<URL>()

        // 1. Mathematical grid intersection for visible and off-screen / incoming rows
        if minRow <= maxRow && minCol <= maxCol {
            for r in minRow...maxRow {
                for c in minCol...maxCol {
                    let idx = r * cols + c
                    if idx >= 0 && idx < items.count {
                        activeDragSelection.insert(items[idx].id)
                    }
                }
            }
        }

        // 2. Exact frame matching for currently rendered items
        for (url, frame) in marqueeState.itemFrames {
            if rect.intersects(frame) {
                activeDragSelection.insert(url)
            }
        }

        var resultSelection = marqueeState.initialSelection
        for url in activeDragSelection {
            resultSelection.insert(url)
        }

        // Deselect items that were added in this drag session but left the marquee box
        let previouslyAdded = navigationState.selectedItemIDs.subtracting(marqueeState.initialSelection)
        let deselected = previouslyAdded.subtracting(activeDragSelection)
        resultSelection.subtract(deselected)

        if resultSelection != navigationState.selectedItemIDs {
            navigationState.selectedItemIDs = resultSelection
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
    let isRenaming: Bool
    let onCommitRename: (String) -> Void
    let onCancelRename: () -> Void
    let onSubfolderNavigate: (URL, Bool) -> Void

    @State private var thumbnail: NSImage? = nil
    @Environment(\.displayScale) private var displayScale
    @State private var isHovering = false

    private var requestSize: CGFloat { ThumbnailService.requestDimension(iconSize) }
    private var isScrolling: Bool { ScrollActivity.shared.isScrolling }

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

            if isRenaming {
                InlineRenameField(
                    initialName: item.name,
                    onCommit: onCommitRename,
                    onCancel: onCancelRename
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
        .task(id: "\(item.url.absoluteString)|\(item.dateModified)|\(item.fileSize)|\(item.isDirectory)|\(requestSize)|\(displayScale)|\(isScrolling)") {
            if !item.isDirectory {
                // A loaded preview stays; new cells keep their icon until scrolling stops.
                guard !isScrolling else { return }
                let image = await ThumbnailService.shared.thumbnail(for: item.url, size: CGSize(width: requestSize, height: requestSize), scale: displayScale)
                guard !Task.isCancelled else { return }
                thumbnail = image
            } else {
                thumbnail = nil
            }
        }
    }
}

extension IconGridItemView: @preconcurrency Equatable {
    static func == (lhs: IconGridItemView, rhs: IconGridItemView) -> Bool {
        lhs.item.id == rhs.item.id &&
        lhs.item.dateModified == rhs.item.dateModified &&
        lhs.item.fileSize == rhs.item.fileSize &&
        lhs.iconSize == rhs.iconSize &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isRenaming == rhs.isRenaming
    }
}

private struct GridScrollSynchronizer: NSViewRepresentable {
    let targetURL: URL?
    let items: [FileItem]
    let iconSize: CGFloat
    let gridColumnCount: Int
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let isDragging: Bool
    let onAutoScrollTick: (CGPoint) -> Void
    let onDragEnded: () -> Void

    final class Coordinator {
        var lastTargetURL: URL?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> GridScrollNSView {
        GridScrollNSView()
    }

    func updateNSView(_ nsView: GridScrollNSView, context: Context) {
        nsView.items = items
        nsView.iconSize = iconSize
        nsView.gridColumnCount = gridColumnCount
        nsView.containerWidth = containerWidth
        nsView.containerHeight = containerHeight
        nsView.isDragging = isDragging
        nsView.onAutoScrollTick = onAutoScrollTick
        nsView.onDragEnded = onDragEnded

        if isDragging {
            nsView.startAutoScrollIfNeeded()
        } else {
            nsView.stopAutoScroll()
        }

        if let targetURL, targetURL != context.coordinator.lastTargetURL {
            context.coordinator.lastTargetURL = targetURL
            nsView.scrollToTargetURL(targetURL)
        } else if targetURL == nil {
            context.coordinator.lastTargetURL = nil
        }
    }

    static func dismantleNSView(_ nsView: GridScrollNSView, coordinator: Coordinator) {
        nsView.stopAutoScroll()
    }
}

private final class GridScrollNSView: NSView {
    var items: [FileItem] = []
    var iconSize: CGFloat = 64
    var gridColumnCount: Int = 4
    var containerWidth: CGFloat = 800
    var containerHeight: CGFloat = 600
    var isDragging: Bool = false
    var onAutoScrollTick: ((CGPoint) -> Void)?
    var onDragEnded: (() -> Void)?

    private var autoScrollTimer: Timer?

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    func startAutoScrollIfNeeded() {
        guard autoScrollTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.handleAutoScrollTick()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    private func handleAutoScrollTick() {
        guard isDragging else {
            stopAutoScroll()
            return
        }

        if NSEvent.pressedMouseButtons == 0 {
            stopAutoScroll()
            DispatchQueue.main.async { [weak self] in
                self?.onDragEnded?()
            }
            return
        }

        guard let scrollView = self.findScrollView,
              let window = scrollView.window,
              let clipView = scrollView.contentView as? NSClipView,
              let docView = scrollView.documentView else { return }

        let mouseLocationInWindow = window.mouseLocationOutsideOfEventStream
        let scrollFrameInWindow = scrollView.convert(scrollView.bounds, to: nil)

        // Margin: 50pt from bottom/top edge of scroll view in window space
        let bottomThreshold = scrollFrameInWindow.minY + 50
        let topThreshold = scrollFrameInWindow.maxY - 50

        var scrollDelta: CGFloat = 0

        if mouseLocationInWindow.y < bottomThreshold {
            // Mouse is near bottom edge or below scroll view -> scroll DOWN
            let distance = max(0, bottomThreshold - mouseLocationInWindow.y)
            scrollDelta = min(36.0, max(5.0, distance * 0.5))
        } else if mouseLocationInWindow.y > topThreshold {
            // Mouse is near top edge or above scroll view -> scroll UP
            let distance = max(0, mouseLocationInWindow.y - topThreshold)
            scrollDelta = -min(36.0, max(5.0, distance * 0.5))
        }

        if scrollDelta != 0 {
            let maxScroll = max(0, docView.frame.height - clipView.bounds.height)
            var origin = clipView.bounds.origin
            let newY = min(maxScroll, max(0, origin.y + scrollDelta))
            if newY != origin.y {
                origin.y = newY
                clipView.scroll(to: origin)
                scrollView.reflectScrolledClipView(clipView)
            }
        }

        let mouseInDoc = docView.convert(mouseLocationInWindow, from: nil)
        DispatchQueue.main.async { [weak self] in
            self?.onAutoScrollTick?(CGPoint(x: mouseInDoc.x, y: mouseInDoc.y))
        }
    }

    func scrollToTargetURL(_ targetURL: URL) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let scrollView = self.findScrollView,
                  let clipView = scrollView.contentView as? NSClipView,
                  let docView = scrollView.documentView else { return }

            guard let targetIndex = self.items.firstIndex(where: { $0.url == targetURL }) else { return }

            let cols = max(1, self.gridColumnCount)
            let targetRow = targetIndex / cols

            let currentIconSize = self.iconSize
            let itemHeight = currentIconSize + 58
            let rowStride = itemHeight + 24
            let rowTop = 20 + CGFloat(targetRow) * rowStride
            let rowBottom = rowTop + itemHeight

            let visibleRect = clipView.documentVisibleRect
            let maxScroll = max(0, docView.frame.height - visibleRect.height)

            if rowBottom > visibleRect.maxY {
                let desiredY = min(maxScroll, rowBottom + 28 - visibleRect.height)
                clipView.scroll(to: NSPoint(x: 0, y: desiredY))
                scrollView.reflectScrolledClipView(clipView)
            } else if rowTop < visibleRect.minY {
                let desiredY = max(0, rowTop - 28)
                clipView.scroll(to: NSPoint(x: 0, y: desiredY))
                scrollView.reflectScrolledClipView(clipView)
            }
        }
    }
}

private extension NSView {
    var findScrollView: NSScrollView? {
        if let sv = self.enclosingScrollView { return sv }
        var view: NSView? = self
        while let current = view {
            if let sv = current as? NSScrollView { return sv }
            if let sv = current.enclosingScrollView { return sv }
            view = current.superview
        }
        return nil
    }
}
