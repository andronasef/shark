import XCTest
import SwiftUI
@testable import Shark

@MainActor
final class FinderPolishAndStatesTests: XCTestCase {

    func testViewModeColumnsProperties() {
        let mode = ViewMode.compact
        XCTAssertEqual(mode.rawValue, "Columns")
        XCTAssertEqual(mode.iconName, "rectangle.split.3x1")
    }

    func testDirectoryEmptyStateCallbacks() {
        var cleared = false
        var created = false

        let emptyWithFilter = DirectoryEmptyStateView(
            isFilterActive: true,
            onClearFilter: { cleared = true },
            onNewFolder: { created = true }
        )
        XCTAssertNotNil(emptyWithFilter)

        let emptyWithoutFilter = DirectoryEmptyStateView(
            isFilterActive: false,
            onClearFilter: { cleared = true },
            onNewFolder: { created = true }
        )
        XCTAssertNotNil(emptyWithoutFilter)
    }

    func testDirectoryErrorStateCallbacks() {
        var retried = false
        var home = false

        let permissionErrorView = DirectoryErrorStateView(
            errorMessage: "The operation couldn’t be completed. Operation not permitted",
            onRetry: { retried = true },
            onGoHome: { home = true }
        )
        XCTAssertNotNil(permissionErrorView)

        let genericErrorView = DirectoryErrorStateView(
            errorMessage: "Device not found",
            onRetry: { retried = true },
            onGoHome: { home = true }
        )
        XCTAssertNotNil(genericErrorView)
    }

    func testDirectoryLoadingViewInitialization() {
        let loadingView = DirectoryLoadingStateView()
        XCTAssertNotNil(loadingView)
    }
}
