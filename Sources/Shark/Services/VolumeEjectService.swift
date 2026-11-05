import AppKit
import Observation

@MainActor
@Observable
final class VolumeEjectService {
    static let shared = VolumeEjectService()
    private(set) var ejecting: Set<URL> = []

    /// Only mounted volume roots are passed by FileSystemService. Unknown metadata fails closed.
    nonisolated static func canEject(_ url: URL, isEjectable: Bool, isRemovable: Bool,
                                     isInternal: Bool?, isLocal: Bool?) -> Bool {
        let path = url.standardizedFileURL.resolvingSymlinksInPath().path
        guard path != "/", !path.hasPrefix("/System/Volumes/") else { return false }
        return isEjectable || isRemovable || isInternal == false || isLocal == false
    }

    /// No force-unmount fallback: macOS reports a busy volume instead of disrupting open files.
    func eject(_ url: URL, operation: @escaping @Sendable (URL) async throws -> Void = unmount) async throws {
        let target = url.standardizedFileURL
        let path = target.resolvingSymlinksInPath().path
        guard path != "/", !path.hasPrefix("/System/Volumes/"), !ejecting.contains(target) else { return }
        ejecting.insert(target)
        defer { ejecting.remove(target) }
        try await operation(target)
    }

    @concurrent private static func unmount(_ url: URL) async throws {
        try NSWorkspace.shared.unmountAndEjectDevice(at: url)
    }
}
