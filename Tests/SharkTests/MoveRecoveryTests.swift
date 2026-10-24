import Foundation
import Testing
@testable import Shark

private final class FailingRecoveryFileManager: FileManager, @unchecked Sendable {
    private var calls = 0
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {
        calls += 1
        if calls == 2 || calls == 3 { throw CocoaError(.fileWriteNoPermission) }
        try super.moveItem(at: srcURL, to: dstURL)
    }
}

struct MoveRecoveryTests {
    @Test func rollbackFailureReportsSurvivingMoveForRecovery() async throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let target = base.appendingPathComponent("target")
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        let a = base.appendingPathComponent("a")
        let b = base.appendingPathComponent("b")
        try Data([1]).write(to: a)
        try Data([2]).write(to: b)
        let service = FileOperationsService(fileManager: FailingRecoveryFileManager())
        do {
            _ = try await service.move(items: [a,b], to: target)
            Issue.record("Expected batch and recovery to fail")
        } catch let error as PartialMoveError {
            #expect(error.remainingMoves.count == 1)
            #expect(error.remainingMoves.first?.source == a)
            #expect(error.remainingMoves.first?.destination == target.appendingPathComponent("a"))
            #expect(error.localizedDescription.contains(target.path))
            #expect(fm.fileExists(atPath: b.path))
        }
    }
}
