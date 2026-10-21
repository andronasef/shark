import XCTest
@testable import Shark

final class UpdateCheckerTests: XCTestCase {

    private func v(_ s: String) -> SemanticVersion { SemanticVersion(s)! }

    private func release(_ tag: String, draft: Bool = false, prerelease: Bool = false, assets: String = "[]") -> GitHubRelease {
        let json = """
        {"tag_name":"\(tag)","draft":\(draft),"prerelease":\(prerelease),
         "html_url":"https://github.com/andronasef/shark/releases/tag/\(tag)","assets":\(assets)}
        """
        return try! JSONDecoder().decode(GitHubRelease.self, from: Data(json.utf8))
    }

    func testSemVerSpecOrdering() {
        let ordered = ["1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-alpha.beta", "1.0.0-beta",
                       "1.0.0-beta.2", "1.0.0-beta.11", "1.0.0-rc.1", "1.0.0"].map(v)
        for (lower, higher) in zip(ordered, ordered.dropFirst()) {
            XCTAssertLessThan(lower, higher)
            XCTAssertFalse(higher < lower)
        }
        XCTAssertTrue(v("1.0.0-alpha").isPrerelease)
        XCTAssertFalse(v("1.0.0").isPrerelease)
    }

    func testNumericCoreOrdering() {
        XCTAssertLessThan(v("1.0.9"), v("1.0.10"))
        XCTAssertGreaterThan(v("2.0.0"), v("1.99.99"))
    }

    func testPrefixAndBuildMetadataAreIgnored() {
        XCTAssertEqual(v("v1.2.3"), v("1.2.3"))
        XCTAssertEqual(v("1.2.3+build.5"), v("1.2.3"))
    }

    func testInvalidStringsDoNotParse() {
        for s in ["1.0", "", "abc", "1.0.x", "1.0.0-", "1.0.0-alpha..1", "-1.0.0"] {
            XCTAssertNil(SemanticVersion(s), s)
        }
    }

    func testDraftIsDroppedEvenWhenHighest() {
        let picked = UpdateChecker.newestRelease(in: [release("v9.0.0", draft: true), release("v1.0.1")],
                                                 newerThan: v("1.0.0"))
        XCTAssertEqual(picked?.tagName, "v1.0.1")
    }

    func testStableUserIgnoresPrereleases() {
        let picked = UpdateChecker.newestRelease(in: [release("v1.1.0-beta", prerelease: true), release("v1.0.1")],
                                                 newerThan: v("1.0.0"))
        XCTAssertEqual(picked?.tagName, "v1.0.1")
    }

    func testPrereleaseUserSeesPrereleases() {
        let picked = UpdateChecker.newestRelease(in: [release("v1.0.0-alpha.1", prerelease: true)],
                                                 newerThan: v("1.0.0-alpha"))
        XCTAssertEqual(picked?.tagName, "v1.0.0-alpha.1")
    }

    func testHighestWinsRegardlessOfOrder() {
        let picked = UpdateChecker.newestRelease(in: [release("v1.0.1"), release("v1.2.0"), release("v1.1.0")],
                                                 newerThan: v("1.0.0"))
        XCTAssertEqual(picked?.tagName, "v1.2.0")
    }

    func testNilWhenNothingNewerOrUnparsable() {
        XCTAssertNil(UpdateChecker.newestRelease(in: [release("v1.0.0"), release("v0.9.0")], newerThan: v("1.0.0")))
        XCTAssertNil(UpdateChecker.newestRelease(in: [release("nightly"), release("latest")], newerThan: v("1.0.0")))
        XCTAssertNil(UpdateChecker.newestRelease(in: [], newerThan: v("1.0.0")))
    }

    func testDownloadURLPrefersDMGAsset() {
        let r = release("v1.0.0-alpha.1", prerelease: true, assets: """
        [{"name":"Shark-1.0.0-alpha.1.dmg.sha256","browser_download_url":"https://example.com/a.sha256"},
         {"name":"Shark-1.0.0-alpha.1.dmg","browser_download_url":"https://example.com/a.dmg"}]
        """)
        XCTAssertEqual(r.downloadURL.absoluteString, "https://example.com/a.dmg")
    }

    func testDownloadURLFallsBackToReleasePage() {
        let r = release("v1.0.0-alpha", prerelease: true, assets: """
        [{"name":"Shark-1.0.0-alpha.zip","browser_download_url":"https://example.com/a.zip"}]
        """)
        XCTAssertEqual(r.downloadURL, r.htmlURL)
    }

    func testChannelPrecedence() {
        XCTAssertEqual(UpdateChecker.channel(hasReceipt: true, hasCask: true), .appStore)
        XCTAssertEqual(UpdateChecker.channel(hasReceipt: false, hasCask: true), .homebrew)
        XCTAssertEqual(UpdateChecker.channel(hasReceipt: false, hasCask: false), .dmg)
    }
}
