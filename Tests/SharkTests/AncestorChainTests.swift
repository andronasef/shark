import XCTest
@testable import Shark

final class AncestorChainTests: XCTestCase {
    func testRootTerminatesForEveryURLForm() {
        for url in [URL(fileURLWithPath: "/"), URL(fileURLWithPath: "/", isDirectory: true), URL(string: "file:///")!] {
            XCTAssertEqual(url.ancestorChain.map(\.path), ["/"], "\(url)")
        }
    }

    func testChainRunsRootFirstAndEndsAtTheURLItself() {
        let url = URL(fileURLWithPath: "/Users/andrew/Documents", isDirectory: true)
        XCTAssertEqual(url.ancestorChain.map(\.path), ["/", "/Users", "/Users/andrew", "/Users/andrew/Documents"])
        XCTAssertEqual(url.ancestorChain.last, url.standardizedFileURL)
    }

    func testDotDotAndTrailingSlashAreNormalised() {
        let url = URL(fileURLWithPath: "/Users/andrew/../andrew/Documents/")
        XCTAssertEqual(url.ancestorChain.map(\.path), ["/", "/Users", "/Users/andrew", "/Users/andrew/Documents"])
    }
}
