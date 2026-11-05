import SwiftUI
import AppKit

struct PhotoViewerView: View {
    @Bindable var state: PhotoViewerState
    let toggleFullScreen: () -> Void
    @State private var dragOrigin: CGSize?
    @State private var magnifyOrigin: CGFloat?
    @State private var scale: CGFloat = 2
    @FocusState private var viewerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            controls.padding(.horizontal, 10).padding(.vertical, 8).background(.bar)
            Divider()
            GeometryReader { geometry in
                ZStack {
                    Color(nsColor: .underPageBackgroundColor)
                    if let error = state.error {
                        ContentUnavailableView(L10n.text("Unable to Open Photo"), systemImage: "photo.badge.exclamationmark", description: Text(error))
                    } else if let image = state.image {
                        let size = displaySize(in: geometry.size)
                        Image(decorative: image, scale: 1)
                            .resizable().interpolation(.high)
                            .scaleEffect(x: state.isFlippedHorizontal ? -1 : 1, y: state.isFlippedVertical ? -1 : 1)
                            .rotationEffect(.degrees(state.rotation))
                            .frame(width: size.width, height: size.height)
                            .offset(state.pan)
                            .accessibilityLabel(state.currentURL?.lastPathComponent ?? L10n.text("Photo"))
                            .gesture(DragGesture().onChanged { value in
                                state.pause()
                                if dragOrigin == nil { dragOrigin = state.pan }
                                state.pan = CGSize(width: (dragOrigin?.width ?? 0) + value.translation.width, height: (dragOrigin?.height ?? 0) + value.translation.height)
                            }.onEnded { _ in dragOrigin = nil })
                            .onTapGesture(count: 2) { state.pause(); state.actualSize.toggle(); state.zoom = 1; state.pan = .zero }
                            .gesture(MagnifyGesture().onChanged { value in
                                state.pause()
                                if magnifyOrigin == nil { magnifyOrigin = state.zoom }
                                state.zoom = min(max((magnifyOrigin ?? 1) * value.magnification, 0.1), 8)
                            }.onEnded { _ in magnifyOrigin = nil })
                            .contextMenu { imageContextMenu }
                    }
                    if state.loading { ProgressView().controlSize(.large) }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            if state.showMetadata {
                metadataFooter
            }
            if state.showFilmstrip && !state.urls.isEmpty {
                Divider()
                thumbnailStrip
            }
        }
        .background(WindowScaleReader(scale: $scale).frame(width: 0, height: 0))
        .focusable()
        .focusEffectDisabled()
        .focused($viewerFocused)
        .onAppear { viewerFocused = true }
        .onDisappear { state.stop() }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            // Navigation
            Button(action: state.previous) { Image(systemName: "chevron.left") }
                .disabled(!state.canGoPrevious)
                .keyboardShortcut(.leftArrow, modifiers: [])
                .help(L10n.text("Previous Photo"))
                .accessibilityLabel(L10n.text("Previous Photo"))

            Button(action: state.next) { Image(systemName: "chevron.right") }
                .disabled(!state.canGoNext)
                .keyboardShortcut(.rightArrow, modifiers: [])
                .help(L10n.text("Next Photo"))
                .accessibilityLabel(L10n.text("Next Photo"))

            Text("\(state.urls.isEmpty ? 0 : state.index + 1) / \(state.urls.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 44)

            Divider().frame(height: 18)

            // Zoom Out / In & Zoom Preset Menu
            Button(action: state.zoomOut) { Image(systemName: "minus.magnifyingglass") }
                .keyboardShortcut("-", modifiers: .command)
                .help(L10n.text("Zoom Out (⌘-)"))
                .accessibilityLabel(L10n.text("Zoom Out"))

            Menu {
                Button(L10n.text("Fit to Window")) { state.zoomToFit() }
                    .keyboardShortcut("0", modifiers: .command)
                Button(L10n.text("Actual Size (100%)")) { state.zoomToActualSize() }
                    .keyboardShortcut("1", modifiers: .command)
                Divider()
                Button("25%") { state.setZoom(factor: 0.25) }
                Button("50%") { state.setZoom(factor: 0.50) }
                Button("75%") { state.setZoom(factor: 0.75) }
                Button("100%") { state.setZoom(factor: 1.00) }
                Button("150%") { state.setZoom(factor: 1.50) }
                Button("200%") { state.setZoom(factor: 2.00) }
                Button("400%") { state.setZoom(factor: 4.00) }
            } label: {
                Text(zoomLabel)
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 42)
            }
            .menuStyle(.borderlessButton)
            .help(L10n.text("Zoom Presets"))

            Button(action: state.zoomIn) { Image(systemName: "plus.magnifyingglass") }
                .keyboardShortcut("+", modifiers: .command)
                .help(L10n.text("Zoom In (⌘+)"))
                .accessibilityLabel(L10n.text("Zoom In"))

            Divider().frame(height: 18)

            // Rotation & Flipping
            Button(action: state.rotateLeft) { Image(systemName: "rotate.left") }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .help(L10n.text("Rotate Counter-Clockwise (⇧⌘R)"))
                .accessibilityLabel(L10n.text("Rotate Counter-Clockwise"))

            Button(action: state.rotateRight) { Image(systemName: "rotate.right") }
                .keyboardShortcut("r", modifiers: .command)
                .help(L10n.text("Rotate Clockwise (⌘R)"))
                .accessibilityLabel(L10n.text("Rotate Clockwise"))

            Menu {
                Button(action: state.flipHorizontal) {
                    Label(L10n.text("Flip Horizontal"), systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                }
                Button(action: state.flipVertical) {
                    Label(L10n.text("Flip Vertical"), systemImage: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                }
                if state.rotation != 0 || state.isFlippedHorizontal || state.isFlippedVertical {
                    Divider()
                    Button(action: state.resetView) {
                        Label(L10n.text("Reset Orientation"), systemImage: "arrow.uturn.backward")
                    }
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .menuStyle(.borderlessButton)
            .help(L10n.text("Flip or Transform"))

            Divider().frame(height: 18)

            // Slideshow
            Button { state.isPlaying ? state.pause() : state.startSlideshow() } label: {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
            }
            .disabled(!state.canGoNext || state.error != nil)
            .keyboardShortcut(.space, modifiers: [])
            .help(state.isPlaying ? L10n.text("Pause Slideshow (Space)") : L10n.text("Start Slideshow (Space)"))
            .accessibilityLabel(state.isPlaying ? L10n.text("Pause Slideshow") : L10n.text("Start Slideshow"))

            Spacer(minLength: 8)

            // Copy & File Operations
            Button(action: state.copyImage) { Image(systemName: "doc.on.doc") }
                .disabled(state.currentURL == nil)
                .keyboardShortcut("c", modifiers: .command)
                .help(L10n.text("Copy Image (⌘C)"))
                .accessibilityLabel(L10n.text("Copy Image"))

            Menu {
                Button(action: state.openInDefaultApp) {
                    Label(L10n.text("Open in Default App"), systemImage: "arrow.up.forward.app")
                }
                Button(action: state.revealInFinder) {
                    Label(L10n.text("Reveal in Finder"), systemImage: "folder")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(state.currentURL == nil)
            .menuStyle(.borderlessButton)
            .help(L10n.text("Open or Share"))

            Button(action: state.deleteCurrentPhoto) { Image(systemName: "trash") }
                .disabled(state.currentURL == nil)
                .keyboardShortcut(.delete, modifiers: .command)
                .help(L10n.text("Move to Trash (⌘⌫)"))
                .accessibilityLabel(L10n.text("Move to Trash"))

            Divider().frame(height: 18)

            // View Toggles
            Button { state.showFilmstrip.toggle() } label: {
                Image(systemName: "rectangle.bottomthird.inset.filled")
                    .foregroundStyle(state.showFilmstrip ? Color.accentColor : Color.secondary)
            }
            .keyboardShortcut("t", modifiers: .command)
            .help(L10n.text("Toggle Thumbnail Filmstrip (⌘T)"))
            .accessibilityLabel(L10n.text("Toggle Thumbnail Filmstrip"))

            Button { state.showMetadata.toggle() } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(state.showMetadata ? Color.accentColor : Color.secondary)
            }
            .keyboardShortcut("i", modifiers: .command)
            .help(L10n.text("Toggle Photo Info (⌘I)"))
            .accessibilityLabel(L10n.text("Toggle Photo Info"))

            Button { toggleFullScreen() } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .help(L10n.text("Toggle Full Screen"))
            .accessibilityLabel(L10n.text("Toggle Full Screen"))
        }
        .buttonStyle(.borderless)
    }

    @ViewBuilder
    private var imageContextMenu: some View {
        Button(L10n.text("Fit to Window")) { state.zoomToFit() }
        Button(L10n.text("Actual Size (100%)")) { state.zoomToActualSize() }
        Button(L10n.text("Zoom In")) { state.zoomIn() }
        Button(L10n.text("Zoom Out")) { state.zoomOut() }
        Divider()
        Button(L10n.text("Rotate Clockwise")) { state.rotateRight() }
        Button(L10n.text("Rotate Counter-Clockwise")) { state.rotateLeft() }
        Button(L10n.text("Flip Horizontal")) { state.flipHorizontal() }
        Button(L10n.text("Flip Vertical")) { state.flipVertical() }
        Divider()
        Button(L10n.text("Copy Image")) { state.copyImage() }
        Button(L10n.text("Open in Default App")) { state.openInDefaultApp() }
        Button(L10n.text("Reveal in Finder")) { state.revealInFinder() }
        Divider()
        Button(role: .destructive, action: state.deleteCurrentPhoto) {
            Label(L10n.text("Move to Trash"), systemImage: "trash")
        }
    }

    private var metadataFooter: some View {
        VStack(spacing: 4) {
            HStack {
                Text(state.currentURL?.lastPathComponent ?? "")
                    .font(.headline)
                    .lineLimit(1)
                    .textSelection(.enabled)
                Spacer()
                Text("\(Int(state.pixels.width)) × \(Int(state.pixels.height)) px")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if state.detailLimited {
                Text(L10n.text("This photo exceeds the full-resolution memory limit. Actual-size geometry is shown with reduced detail."))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !state.metadata.isEmpty {
                Text(state.metadata)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var zoomLabel: String {
        if state.actualSize {
            return "100%"
        }
        return "\(Int(round(state.zoom * 100)))%"
    }
    private var thumbnailStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(state.urls.indices, id: \.self) { index in
                        let url = state.urls[index]
                        Button { state.select(index) } label: {
                            PhotoStripThumbnail(url: url)
                                .frame(width: 70, height: 54)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(index == state.index ? Color.accentColor : .clear, lineWidth: 2))
                        }.buttonStyle(.plain).id(index).help(url.lastPathComponent)
                            .accessibilityLabel(url.lastPathComponent).accessibilityAddTraits(index == state.index ? .isSelected : [])
                    }
                }.padding(10)
            }.frame(height: 78)
                .onChange(of: state.index, initial: true) { _, index in proxy.scrollTo(index, anchor: .center) }
        }
    }
    private func interact(_ action: () -> Void) { state.pause(); action() }
    private func displaySize(in available: CGSize) -> CGSize {
        let natural = PhotoViewerState.actualPointSize(pixels: state.pixels, scale: scale)
        guard natural.width > 0, natural.height > 0 else { return .zero }
        let rotated = Int(state.rotation / 90) % 2 != 0
        let width = rotated ? natural.height : natural.width
        let height = rotated ? natural.width : natural.height
        let fit = min(max(available.width - 32, 1) / width, max(available.height - 32, 1) / height)
        let factor = (state.actualSize ? 1 : fit) * state.zoom
        return CGSize(width: natural.width * factor, height: natural.height * factor)
    }
}

private struct PhotoStripThumbnail: View {
    let url: URL
    @State private var image: NSImage?
    var body: some View {
        Group {
            if let image { Image(nsImage: image).resizable().scaledToFit() }
            else { Image(systemName: "photo").foregroundStyle(.secondary) }
        }.padding(3).task(id: url) {
            let result = await ThumbnailService.shared.thumbnail(for: url, size: CGSize(width: 70, height: 54))
            guard !Task.isCancelled else { return }
            image = result
        }.onDisappear { image = nil }
    }
}

private struct WindowScaleReader: NSViewRepresentable {
    @Binding var scale: CGFloat
    func makeNSView(context: Context) -> ScaleView {
        let view = ScaleView()
        view.changed = { value in DispatchQueue.main.async { scale = value } }
        return view
    }
    func updateNSView(_ nsView: ScaleView, context: Context) {}
    final class ScaleView: NSView {
        var changed: ((CGFloat) -> Void)?
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); changed?(window?.backingScaleFactor ?? 1) }
        override func viewDidChangeBackingProperties() { super.viewDidChangeBackingProperties(); changed?(window?.backingScaleFactor ?? 1) }
    }
}
