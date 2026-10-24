import XCTest
import AppKit
@testable import Shark

@MainActor
final class PhotoViewerTests: XCTestCase {
    let urls = ["one.jpg", "two.png", "three.gif"].map { URL(fileURLWithPath: "/tmp/\($0)") }

    func testSnapshotBoundariesAndReset() {
        let state = PhotoViewerState(urls: urls, initialURL: urls[0])
        XCTAssertFalse(state.canGoPrevious)
        state.zoom = 3
        state.rotation = 90
        state.next()
        XCTAssertEqual(state.currentURL, urls[1])
        XCTAssertEqual(state.zoom, 1)
        XCTAssertEqual(state.rotation, 0)
        state.next()
        state.next()
        XCTAssertEqual(state.currentURL, urls[2])
        XCTAssertFalse(state.canGoNext)
    }

    func testSelectedSnapshotPreservesFolderOrder() {
        let items = urls.map { FileItem(url: $0, name: $0.lastPathComponent, isDirectory: false) }
        XCTAssertEqual(PhotoViewerWindowController.snapshot(items: items, selectedURLs: [urls[2], urls[0]]), [urls[0], urls[2]])
    }

    func testMissingAndCorruptHaveExplanation() async {
        let missing = await PhotoImageDecoder.shared.decode(url: urls[0], maxPixel: 100)
        XCTAssertNotNil(missing.error)
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try? Data("not an image".utf8).write(to: temp)
        defer { try? FileManager.default.removeItem(at: temp) }
        let corrupt = await PhotoImageDecoder.shared.decode(url: temp, maxPixel: 100)
        XCTAssertNotNil(corrupt.error)
    }

    func testStaleLoadsAndSlideshowEnd() {
        let state = PhotoViewerState(urls: urls, initialURL: urls[0])
        let old = state.loadGeneration
        state.next()
        XCTAssertFalse(state.acceptsLoad(generation: old))
        state.next()
        state.startSlideshow()
        XCTAssertFalse(state.isPlaying)
    }

    func testRasterBudgetHandlesExtremeDimensionsWithoutOverflow() {
        XCTAssertTrue(PhotoImageDecoder.fitsRasterBudget(width: 32000, height: 100))
        XCTAssertFalse(PhotoImageDecoder.fitsRasterBudget(width: 100000, height: 100000))
        XCTAssertFalse(PhotoImageDecoder.fitsRasterBudget(width: Int.max, height: Int.max))
        XCTAssertFalse(PhotoImageDecoder.fitsRasterBudget(width: 0, height: 100))
    }

    func testActualSizePreservesPanoramaDetailWithinBudget() async throws {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 6000, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try XCTUnwrap(bitmap.representation(using: .png, properties: [:])).write(to: temp)
        defer { try? FileManager.default.removeItem(at: temp) }
        let result = await PhotoImageDecoder.shared.decode(url: temp, maxPixel: 4096, actualSize: true)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.image?.width, 6000)
        XCTAssertFalse(result.detailLimited)
    }

    func testActualSizeUsesDisplayPixels() {
        XCTAssertEqual(PhotoViewerState.actualPointSize(pixels: CGSize(width: 4000, height: 3000), scale: 2), CGSize(width: 2000, height: 1500))
    }
}
