import AppKit
import Observation

@MainActor @Observable
final class PhotoViewerState {
    var urls: [URL]
    private(set) var index: Int
    var zoom: CGFloat = 1
    var actualSize = false { didSet { if oldValue != actualSize && !resettingView { load() } } }
    var detailLimited = false
    var rotation: Double = 0
    var isFlippedHorizontal = false
    var isFlippedVertical = false
    var pan: CGSize = .zero
    var image: CGImage?
    var pixels: CGSize = .zero
    var metadata = ""
    var error: String?
    var loading = false
    var isPlaying = false
    var active = true
    var showFilmstrip = true
    var showMetadata = true
    private(set) var loadGeneration = UUID()
    @ObservationIgnored private let decoder = PhotoImageDecoder()
    @ObservationIgnored private var resettingView = false
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
    func first() { select(0) }
    func last() { select(urls.count - 1) }
    func select(_ newIndex: Int) {
        pause()
        guard urls.indices.contains(newIndex), newIndex != index else { return }
        index = newIndex
        resetView()
        load()
    }
    func resetView() {
        resettingView = true
        zoom = 1; actualSize = false; rotation = 0; pan = .zero
        isFlippedHorizontal = false; isFlippedVertical = false
        resettingView = false
    }

    func rotateRight() {
        pause()
        rotation = (rotation + 90).truncatingRemainder(dividingBy: 360)
    }

    func rotateLeft() {
        pause()
        rotation = (rotation - 90).truncatingRemainder(dividingBy: 360)
    }

    func flipHorizontal() {
        pause()
        isFlippedHorizontal.toggle()
    }

    func flipVertical() {
        pause()
        isFlippedVertical.toggle()
    }

    func zoomIn() {
        pause()
        actualSize = false
        zoom = min(8, zoom * 1.25)
    }

    func zoomOut() {
        pause()
        actualSize = false
        zoom = max(0.1, zoom / 1.25)
    }

    func zoomToFit() {
        pause()
        actualSize = false
        zoom = 1
        pan = .zero
    }

    func zoomToActualSize() {
        pause()
        actualSize = true
        zoom = 1
        pan = .zero
    }

    func setZoom(factor: CGFloat) {
        pause()
        actualSize = false
        zoom = min(max(factor, 0.1), 8)
        pan = .zero
    }

    /// The file and, when decoded, its image.
    private func copyObjects() -> [NSPasteboardWriting] {
        guard let currentURL else { return [] }
        var objects: [NSPasteboardWriting] = [currentURL as NSURL]
        if let image, let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]),
           let nsImage = NSImage(data: data) {
            objects.append(nsImage)
        }
        return objects
    }

    func copyImage() {
        let objects = copyObjects()
        guard !objects.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(objects)
    }

    func revealInFinder() {
        guard let currentURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([currentURL])
    }

    func openInDefaultApp() {
        guard let currentURL else { return }
        NSWorkspace.shared.open(currentURL)
    }

    /// Moves the current photo to the Trash and drops it from the viewer only once that has succeeded,
    /// so a failed move never makes a photo that is still on disk disappear.
    func deleteCurrentPhoto() {
        guard let target = currentURL else { return }
        pause()
        Task {
            do {
                let restorations = try await FileOperationsService.shared.trash(items: [target])
                FileUndoService.shared.record(.trash(restorations: restorations))
                remove(target)
            } catch {
                self.error = L10n.format("Move to Trash failed: %@", error.localizedDescription)
            }
        }
    }

    /// Removes a photo from the list, keeping the index on a valid photo.
    func remove(_ url: URL) {
        urls.removeAll { $0 == url }
        if urls.isEmpty {
            image = nil
            error = L10n.text("No photos remaining.")
            return
        }
        index = min(index, urls.count - 1)
        resetView()
        load()
    }

    func load() {
        loader?.cancel()
        let generation = UUID()
        loadGeneration = generation
        image = nil; error = nil; detailLimited = false; loading = true
        guard let url = currentURL else { loading = false; return }
        let fullDetail = actualSize
        let decoder = decoder
        loader = Task { [weak self] in
            var frame = 0
            repeat {
                guard !Task.isCancelled else { return }
                let result = await decoder.decode(url: url, maxPixel: 4096, frame: frame, actualSize: fullDetail)
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
                self.resetView()
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
