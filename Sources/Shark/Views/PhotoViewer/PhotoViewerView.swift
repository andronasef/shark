import SwiftUI
import AppKit

struct PhotoViewerView: View {
    @Bindable var state: PhotoViewerState
    let toggleFullScreen: () -> Void
    @State private var dragOrigin: CGSize?
    @State private var magnifyOrigin: CGFloat?
    @State private var showMetadata = true
    @State private var scale: CGFloat = 2
    @FocusState private var viewerFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            controls.padding(10).background(.bar)
            GeometryReader { geometry in
                ZStack {
                    Color(nsColor: .underPageBackgroundColor)
                    if let error = state.error {
                        ContentUnavailableView(L10n.text("Unable to Open Photo"), systemImage: "photo.badge.exclamationmark", description: Text(error))
                    } else if let image = state.image {
                        let size = displaySize(in: geometry.size)
                        Image(decorative: image, scale: 1)
                            .resizable().interpolation(.high)
                            .frame(width: size.width, height: size.height)
                            .rotationEffect(.degrees(state.rotation))
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
                    }
                    if state.loading { ProgressView().controlSize(.large) }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                // The zoomed image is larger than the viewport; keep it inside so it never covers the info and strip.
                .clipped()
            }
            VStack(spacing: 4) {
                HStack {
                    Text(state.currentURL?.lastPathComponent ?? "").font(.headline).lineLimit(1).textSelection(.enabled)
                    Spacer()
                    Text("\(state.urls.isEmpty ? 0 : state.index + 1) / \(state.urls.count)").monospacedDigit().foregroundStyle(.secondary)
                }
                if state.detailLimited {
                    Text(L10n.text("This photo exceeds the full-resolution memory limit. Actual-size geometry is shown with reduced detail."))
                        .font(.caption).foregroundStyle(.orange).frame(maxWidth: .infinity, alignment: .leading)
                }
                if showMetadata { Text(state.metadata).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
            }.padding(12)
            thumbnailStrip
        }
        .background(WindowScaleReader(scale: $scale).frame(width: 0, height: 0))
        .focusable()
        .focusEffectDisabled()
        .focused($viewerFocused)
        .onAppear { viewerFocused = true }
        .onDisappear { state.stop() }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: state.previous) { Image(systemName: "chevron.left") }.disabled(!state.canGoPrevious).keyboardShortcut(.leftArrow, modifiers: []).help(L10n.text("Previous Photo")).accessibilityLabel(L10n.text("Previous Photo"))
            Button(action: state.next) { Image(systemName: "chevron.right") }.disabled(!state.canGoNext).keyboardShortcut(.rightArrow, modifiers: []).help(L10n.text("Next Photo")).accessibilityLabel(L10n.text("Next Photo"))
            Divider().frame(height: 20)
            Button { interact { state.actualSize = false; state.zoom = 1; state.pan = .zero } } label: { Text(L10n.text("Fit")) }.help(L10n.text("Fit Photo to Window"))
            Button { interact { state.actualSize = true; state.zoom = 1; state.pan = .zero } } label: { Text(L10n.text("Actual Size")) }.help(L10n.text("One image pixel per display pixel"))
            Button { interact { state.zoom = max(0.1, state.zoom / 1.25) } } label: { Image(systemName: "minus.magnifyingglass") }.keyboardShortcut("-", modifiers: .command).accessibilityLabel(L10n.text("Zoom Out"))
            Button { interact { state.zoom = min(8, state.zoom * 1.25) } } label: { Image(systemName: "plus.magnifyingglass") }.keyboardShortcut("+", modifiers: .command).accessibilityLabel(L10n.text("Zoom In"))
            Spacer(minLength: 0)
            Button { interact { state.rotation += 90 } } label: { Image(systemName: "rotate.right") }.help(L10n.text("Rotate View Clockwise")).accessibilityLabel(L10n.text("Rotate View Clockwise"))
            Button { state.isPlaying ? state.pause() : state.startSlideshow() } label: { Image(systemName: state.isPlaying ? "pause.fill" : "play.fill") }.disabled(!state.canGoNext || state.error != nil).help(L10n.text("Slideshow")).accessibilityLabel(state.isPlaying ? L10n.text("Pause Slideshow") : L10n.text("Start Slideshow"))
            Button { interact { showMetadata.toggle() } } label: { Image(systemName: "info.circle") }.help(L10n.text("Show Photo Information")).accessibilityLabel(L10n.text("Show Photo Information"))
            Button { interact { toggleFullScreen() } } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }.help(L10n.text("Toggle Full Screen")).accessibilityLabel(L10n.text("Toggle Full Screen"))
        }.buttonStyle(.borderless)
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
