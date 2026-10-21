import XCTest
@testable import Shark

final class AppLinksTests: XCTestCase {
    @MainActor
    func testURLsAreValidAndMatchExpectedEndpoints() {
        XCTAssertEqual(AppLinks.repository.absoluteString, "https://github.com/andronasef/shark")
        XCTAssertEqual(AppLinks.website.absoluteString, "https://shark.andronasef.com/")
        XCTAssertEqual(AppLinks.features.absoluteString, "https://shark.andronasef.com/features/")
        XCTAssertEqual(AppLinks.author.absoluteString, "https://andronasef.com/")
        XCTAssertEqual(AppLinks.feedback.absoluteString, "https://userhq.increasinglabs.com/increasing-labs/shark")

        for url in [AppLinks.repository, AppLinks.website, AppLinks.features, AppLinks.author, AppLinks.feedback] {
            XCTAssertEqual(url.scheme, "https")
            XCTAssertFalse(url.host?.isEmpty ?? true)
        }
    }
}
