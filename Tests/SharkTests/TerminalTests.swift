import XCTest
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

    func testPTYSessionInit() {
        XCTAssertEqual(session.currentWorkingDirectory, tempDir)
        XCTAssertFalse(session.isRunning)
        XCTAssertTrue(session.outputText.isEmpty)
    }

    func testPTYSessionDirectorySync() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        session.syncDirectory(to: home)
        XCTAssertEqual(session.currentWorkingDirectory, home)
    }

    func testPTYSessionClear() {
        session.outputText = "Hello Terminal"
        session.clear()
        XCTAssertTrue(session.outputText.isEmpty)
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
