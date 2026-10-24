import XCTest
import Observation
@testable import Shark

@MainActor
final class TerminalTests: XCTestCase {
    var session: PTYSession!
    let tempDir = FileManager.default.temporaryDirectory

    override func setUp() async throws {
        session = PTYSession(workingDirectory: tempDir)
    }

    override func tearDown() async throws {
        session.terminate()
    }

    func testTerminalVisibilityNotifiesViewsOnOpenAndClose() {
        let workspace = WorkspaceState()
        for visible in [true, false] {
            let changed = expectation(description: "Terminal visibility changes to \(visible)")
            withObservationTracking {
                _ = workspace.isTerminalVisible
            } onChange: {
                changed.fulfill()
            }
            workspace.isTerminalVisible = visible
            wait(for: [changed], timeout: 0.2)
        }
    }

    func testPTYSessionInit() {
        XCTAssertEqual(session.currentWorkingDirectory, tempDir)
        XCTAssertFalse(session.isRunning)
        XCTAssertTrue(session.outputText.isEmpty)
    }

    func testPTYSessionDirectorySync() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        session.syncDirectory(to: home)
        XCTAssertEqual(session.currentWorkingDirectory, tempDir, "Browsing must never claim that a shell cd succeeded")
    }

    func testUseDirectoryPreservesUnfinishedInputAndCopiesOnly() throws {
        session.outputText = "echo unfinished"
        let command = try session.useDirectory(tempDir)
        XCTAssertEqual(command, "cd -- " + tempDir.path.shellQuoted)
        XCTAssertEqual(session.outputText, "echo unfinished")
        XCTAssertFalse(command.contains("\n"))
        XCTAssertFalse(command.contains("\u{15}"))
        XCTAssertThrowsError(try session.useDirectory(tempDir.appendingPathComponent(UUID().uuidString)))
    }

    func testFontPreferenceIsBoundedAndPersistent() {
        let defaults = UserDefaults(suiteName: "TerminalTests." + UUID().uuidString)!
        let first = PTYSession(workingDirectory: tempDir, preferences: defaults)
        XCTAssertEqual(first.fontSize, 12)
        first.adjustFontSize(by: 100)
        XCTAssertEqual(first.fontSize, 36)
        XCTAssertEqual(PTYSession(preferences: defaults).fontSize, 36)
        first.adjustFontSize(by: -100)
        XCTAssertEqual(first.fontSize, 8)
        first.resetFontSize()
        XCTAssertEqual(first.fontSize, 12)
    }

    func testPTYSessionClear() {
        session.outputText = "Hello Terminal"
        session.clear()
        XCTAssertTrue(session.outputText.isEmpty)
    }

    func testTerminalViewRetainedAndNaturalExitReported() async {
        session.start()
        let original = session.terminalView
        XCTAssertTrue(session.makeTerminalView() === original)
        session.sendInput("exit 7\n")
        for _ in 0..<100 where session.isRunning {
            try? await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertFalse(session.isRunning)
        XCTAssertNotNil(session.exitCode)
        XCTAssertTrue(session.makeTerminalView() === original, "Exited scrollback remains available")
        session.restart()
        XCTAssertTrue(session.isRunning)
        XCTAssertFalse(session.terminalView === original)
    }

    func testPTYSessionStartAndTerminate() async {
        session.start()
        XCTAssertTrue(session.isRunning)

        // Allow shell to spin up
        try? await Task.sleep(nanoseconds: 200_000_000)

        session.sendInput("echo 'SharkTerminalTest'\n")
        try? await Task.sleep(nanoseconds: 300_000_000)

        session.terminate()
        XCTAssertFalse(session.isRunning)
    }
}
