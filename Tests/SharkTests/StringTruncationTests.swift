import XCTest
@testable import Shark

final class StringTruncationTests: XCTestCase {
    func testShortNamesAreUnchanged() {
        XCTAssertEqual("Pictures".middleTruncated(to: 24), "Pictures")
    }

    func testLongNamesKeepStartAndExtension() {
        let result = "Screenshot_2026-10-11-13-21-34-58_601.png".middleTruncated(to: 24)
        XCTAssertEqual(result.count, 24)
        XCTAssertTrue(result.hasPrefix("Screenshot_"))
        XCTAssertTrue(result.hasSuffix("601.png"))
        XCTAssertTrue(result.contains("…"))
    }
}
