import XCTest
@testable import Shark

/// Opt in with SHARK_RUN_PERFORMANCE_TESTS=1 and run an optimized test build.
/// Results are measurements, not machine-dependent pass/fail thresholds.
@MainActor
final class BrowsingPerformanceTests: XCTestCase {
    private func requirePerformanceRun() throws {
        guard ProcessInfo.processInfo.environment["SHARK_RUN_PERFORMANCE_TESTS"] == "1" else {
            throw XCTSkip("Run with SHARK_RUN_PERFORMANCE_TESTS=1 in release configuration")
        }
    }

    private func items(count: Int) -> [FileItem] {
        (0..<count).map { index in
            FileItem(url: URL(fileURLWithPath: "/tmp/shark-benchmark/file-\(index)"),
                     name: String(format: "file-%05d", index), isDirectory: false,
                     fileSize: Int64(index * 1024), dateModified: Date(timeIntervalSince1970: 1_700_000_000 + Double(index)))
        }
    }

    func testFilteringTenThousandItems() throws {
        try requirePerformanceRun()
        let navigation = NavigationState()
        navigation.items = items(count: 10_000)
        measure {
            for query in ["file-0", "file-00", "file-009", ""] { navigation.filterText = query }
            XCTAssertEqual(navigation.filteredAndSortedItems.count, 10_000)
        }
    }

    func testSelectionSummaryInLargeDirectory() throws {
        try requirePerformanceRun()
        let navigation = NavigationState()
        navigation.items = items(count: 10_000)
        navigation.selectedItemIDs = Set(navigation.items.prefix(5_000).map(\.id))
        measure {
            XCTAssertEqual(navigation.selectedItems.count, 5_000)
            XCTAssertEqual(navigation.selectedTotalSize, 12_797_440_000)
        }
    }

    func testFormattingTenThousandRows() throws {
        try requirePerformanceRun()
        let rows = items(count: 10_000)
        measure {
            var characters = 0
            for item in rows {
                characters += item.formattedSize.count
                characters += item.dateModified.formatted(date: .abbreviated, time: .shortened).count
            }
            XCTAssertGreaterThan(characters, 10_000)
        }
    }

    func testRepeatedExpandedTreeProjection() async throws {
        try requirePerformanceRun()
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for index in 0..<1_000 {
            try FileManager.default.createDirectory(at: root.appendingPathComponent("folder-\(index)"), withIntermediateDirectories: false)
        }
        let suite = "shark-benchmark-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let tree = FolderTreeModel(defaults: defaults)
        let roots = [FolderTreeRoot(url: root, name: "Root", icon: "folder")]
        await tree.expand(root, showHidden: false)
        _ = tree.rows(for: roots)
        measure {
            for _ in 0..<1_000 { XCTAssertEqual(tree.rows(for: roots).count, 1_001) }
        }
    }
}
