import AppKit
import Observation

@MainActor @Observable
final class PhotoViewerState {
    let urls: [URL]
    private(set) var index: Int
    var zoom: CGFloat = 1
    var actualSize = false { didSet { if oldValue != actualSize { load() } } }
    var detailLimited = false
    var rotation: Double = 0
    var pan: CGSize = .zero
    var image: CGImage?
    var pixels: CGSize = .zero
    var metadata = ""
    var error: String?
    var loading = false
    var isPlaying = false
    var active = true
    private(set) var loadGeneration = UUID()
    private var loader: Task<Void, Never>?
    private var slideshow: Task<Void, Never>?

    init(urls: [URL], initialURL: URL) {
        self.urls = urls
        index = urls.firstIndex(of: initialURL) ?? 0
    }
    var currentURL: URL? { urls.indices.contains(index) ? urls[index] : nil }
    var canGoPrevious: Bool { index > 0 }
    var canGoNext: Bool { index + 1 < urls.count }
    static func actualPointSize(pixels: CGSize, scale: CGFloat) -> CGSize {
        CGSize(width: pixels.width / max(scale, 1), height: pixels.height / max(scale, 1))
    }
    func acceptsLoad(generation: UUID) -> Bool { generation == loadGeneration }
    func next() { select(index + 1) }
    func previous() { select(index - 1) }
    func select(_ newIndex: Int) {
        pause()
        guard urls.indices.contains(newIndex), newIndex != index else { return }
        index = newIndex
        zoom = 1; actualSize = false; rotation = 0; pan = .zero
        load()
    }
    func load() {
        loader?.cancel()
        let generation = UUID()
        loadGeneration = generation
        image = nil; error = nil; detailLimited = false; loading = true
        guard let url = currentURL else { loading = false; return }
        let fullDetail = actualSize
        loader = Task { [weak self] in
            var frame = 0
            repeat {
                guard !Task.isCancelled else { return }
                let result = await PhotoImageDecoder.shared.decode(url: url, maxPixel: 4096, frame: frame, actualSize: fullDetail)
                guard !Task.isCancelled, let self, self.acceptsLoad(generation: generation) else { return }
                self.image = result.image; self.pixels = result.pixels
                self.detailLimited = result.detailLimited
                self.metadata = result.metadata; self.error = result.error; self.loading = false
                if result.error != nil { self.pause() }
                guard result.frameCount > 1, self.active, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
                frame = (frame + 1) % result.frameCount
                do { try await Task.sleep(for: .seconds(result.duration)) } catch { return }
            } while !Task.isCancelled
        }
    }
    func pause() { isPlaying = false; slideshow?.cancel(); slideshow = nil }
    func startSlideshow() {
        pause()
        guard canGoNext, error == nil, active else { return }
        isPlaying = true
        slideshow = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                guard let self, self.isPlaying, self.active, self.error == nil, self.canGoNext else { self?.pause(); return }
                self.index += 1
                self.zoom = 1; self.actualSize = false; self.rotation = 0; self.pan = .zero
                self.load()
                if !self.canGoNext { self.pause(); return }
            }
        }
    }
    func setActive(_ value: Bool) {
        active = value
        if value { load() } else { pause(); loader?.cancel() }
    }
    func stop() { pause(); loader?.cancel(); loadGeneration = UUID() }
}
