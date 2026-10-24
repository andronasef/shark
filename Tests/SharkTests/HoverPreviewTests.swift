import AppKit
import ImageIO
import XCTest
@testable import Shark

@MainActor
final class HoverPreviewTests: XCTestCase {
    func testPreviewWaitsForConfiguredDelay() async throws {
        let controller = HoverPreviewController()
        controller.update(isHovering: true, enabled: true, url: URL(fileURLWithPath: "/sample.txt"),
                          isDirectory: false, delayMilliseconds: 80)
        XCTAssertFalse(controller.isPresented)
        try await Task.sleep(for: .milliseconds(140))
        XCTAssertTrue(controller.isPresented)
        controller.cancel()
        XCTAssertFalse(controller.isPresented)
    }

    func testLeavingBeforeDelayPreventsPreview() async throws {
        let controller = HoverPreviewController()
        for hovering in [true, false] {
            controller.update(isHovering: hovering, enabled: true, url: URL(fileURLWithPath: "/sample.png"),
                              isDirectory: false, delayMilliseconds: 40)
        }
        try await Task.sleep(for: .milliseconds(90))
        XCTAssertFalse(controller.isPresented)
    }

    func testDisabledUnsupportedAndDirectoryItemsDoNotPresent() async throws {
        for (enabled, path, directory) in [(false, "/sample.txt", false), (true, "/sample.zip", false), (true, "/folder.txt", true)] {
            let controller = HoverPreviewController()
            controller.update(isHovering: true, enabled: enabled, url: URL(fileURLWithPath: path),
                              isDirectory: directory, delayMilliseconds: 0)
            try await Task.sleep(for: .milliseconds(10))
            XCTAssertFalse(controller.isPresented)
        }
    }

    func testDisablingDismissesVisiblePreview() async throws {
        let controller = HoverPreviewController()
        let url = URL(fileURLWithPath: "/sample.pdf")
        controller.update(isHovering: true, enabled: true, url: url, isDirectory: false, delayMilliseconds: 0)
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertTrue(controller.isPresented)
        controller.update(isHovering: true, enabled: false, url: url, isDirectory: false, delayMilliseconds: 0)
        XCTAssertFalse(controller.isPresented)
    }

    func testSupportsTextImageMediaAndDocumentsButNotArchives() {
        let service = HoverPreviewService.shared
        for name in ["a.txt", "a.gif", "a.mp4", "a.mp3", "a.pdf", "Makefile", "a.swift"] {
            XCTAssertTrue(service.supportsPreview(for: URL(fileURLWithPath: "/tmp/\(name)")), name)
        }
        for name in ["a.zip", "a.dmg", "noextension"] {
            XCTAssertFalse(service.supportsPreview(for: URL(fileURLWithPath: "/tmp/\(name)")), name)
        }
    }

    func testTextCutMidCharacterStillPreviews() async throws {
        // 1 + 2n bytes puts the 32 KiB read boundary inside a two-byte character.
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hover-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try ("a" + String(repeating: "é", count: 20_000)).write(to: url, atomically: true, encoding: .utf8)
        guard case .text(_, _, let encoding, _, let truncated) = await HoverPreviewService.shared.fetchPreview(for: url) else {
            return XCTFail("Expected a text preview")
        }
        XCTAssertEqual(encoding, "UTF-8")
        XCTAssertTrue(truncated)
    }

    func testBinaryDataIsNotPreviewedAsText() {
        XCTAssertNil(HoverPreviewService.decode(Data([0x89, 0x50, 0x00, 0x47, 0x0D])))
    }

    func testShiftOnlyModeWaitsForShift() async throws {
        let controller = HoverPreviewController()
        controller.update(isHovering: true, enabled: true, url: URL(fileURLWithPath: "/sample.txt"),
                          isDirectory: false, delayMilliseconds: 0, requireShift: true)
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertFalse(controller.isPresented)
        controller.cancel()
    }

    func testVisiblePreviewSurvivesBriefLeaveThenDismisses() async throws {
        let controller = HoverPreviewController()
        let url = URL(fileURLWithPath: "/sample.txt")
        controller.update(isHovering: true, enabled: true, url: url, isDirectory: false, delayMilliseconds: 0)
        try await Task.sleep(for: .milliseconds(20))
        controller.update(isHovering: false, enabled: true, url: url, isDirectory: false, delayMilliseconds: 0)
        XCTAssertTrue(controller.isPresented)
        controller.update(isHovering: true, enabled: true, url: url, isDirectory: false, delayMilliseconds: 0)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(controller.isPresented, "Re-entering the row keeps the preview")
        controller.update(isHovering: false, enabled: true, url: url, isDirectory: false, delayMilliseconds: 0)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(controller.isPresented)
    }
    func testLargeImageIsDownsampledAndCacheIsByteBounded() async throws {
        let service = HoverPreviewService.shared
        service.clearCache()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory); service.clearCache() }
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2048, pixelsHigh: 1536,
                                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                                   isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        for index in 0..<5 {
            let url = directory.appendingPathComponent("image-\(index).png")
            try png.write(to: url)
            guard case .image(let image, let dimensions, _) = await service.fetchPreview(for: url) else {
                return XCTFail("Expected image preview")
            }
            XCTAssertEqual(dimensions, CGSize(width: 2048, height: 1536))
            let pixels = HoverPreviewService.pixelSize(of: image)
            XCTAssertLessThanOrEqual(max(pixels.width, pixels.height), CGFloat(HoverPreviewService.imagePixelLimit))
            XCTAssertGreaterThan(service.cachedByteCount, 0)
            XCTAssertLessThanOrEqual(service.cachedByteCount, HoverPreviewService.cacheByteLimit)
        }
    }

    func testCanceledFetchDoesNotPopulateCache() async throws {
        let service = HoverPreviewService.shared
        service.clearCache()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hover-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url); service.clearCache() }
        try "Sample".write(to: url, atomically: true, encoding: .utf8)
        let task = Task { await service.fetchPreview(for: url) }
        task.cancel()
        guard case .unsupported = await task.value else { return XCTFail("Canceled fetch must not publish data") }
        XCTAssertEqual(service.cachedByteCount, 0)
    }

    func testTextReadAndLineCountAreBounded() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hover-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try String(repeating: "x\n", count: 100_000).write(to: url, atomically: true, encoding: .utf8)
        guard case .text(let lines, let total, _, _, let truncated) = await HoverPreviewService.shared.fetchPreview(for: url) else {
            return XCTFail("Expected text preview")
        }
        XCTAssertEqual(lines.count, HoverPreviewService.previewLineLimit)
        XCTAssertEqual(total, HoverPreviewService.textReadLimit / 2 + 1)
        XCTAssertTrue(truncated)
    }

    func testChangedRevisionDoesNotReuseCachedText() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hover-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url); HoverPreviewService.shared.clearCache() }
        try "Before".write(to: url, atomically: true, encoding: .utf8)
        _ = await HoverPreviewService.shared.fetchPreview(for: url)
        try "After with a different size".write(to: url, atomically: true, encoding: .utf8)
        guard case .text(let lines, _, _, _, _) = await HoverPreviewService.shared.fetchPreview(for: url) else {
            return XCTFail("Expected revised text preview")
        }
        XCTAssertEqual(lines, ["After with a different size"])
    }

    func testHoverPreviewPanelSizingIsNotTinyDot() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("hover-\(UUID().uuidString).txt")
        defer {
            try? FileManager.default.removeItem(at: url)
            HoverPreviewPanel.shared.hide(ownerURL: url)
        }
        try "Line 1\nLine 2\nLine 3".write(to: url, atomically: true, encoding: .utf8)
        let item = FileItem(url: url, name: url.lastPathComponent, isDirectory: false)

        HoverPreviewPanel.shared.show(item) {}
        try await Task.sleep(for: .milliseconds(200))

        let panel = Mirror(reflecting: HoverPreviewPanel.shared).children.first { $0.label == "panel" }?.value as? NSPanel
        let unwrappedPanel = try XCTUnwrap(panel)
        XCTAssertGreaterThan(unwrappedPanel.frame.width, 100, "Panel width must not be a tiny dot: \(unwrappedPanel.frame)")
        XCTAssertGreaterThan(unwrappedPanel.frame.height, 60, "Panel height must not be a tiny dot: \(unwrappedPanel.frame)")
    }
}
