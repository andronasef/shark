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
}
