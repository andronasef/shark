import AppKit

/// Always opens the target with Terminal explicitly, never its default folder app.
@MainActor
struct TerminalOpener {
    static let shared = TerminalOpener()
    var findApplication: () -> URL? = {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
    }
    var openURLs: @MainActor ([URL], URL) async throws -> Void = { urls, application in
        _ = try await NSWorkspace.shared.open(urls, withApplicationAt: application, configuration: .init())
    }

    func open(at url: URL) async throws {
        let directory = try Self.directory(for: url)
        guard let application = findApplication() else {
            throw NSError(domain: "Shark.Terminal", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Terminal.app could not be found."])
        }
        try await openURLs([directory], application)
    }

    static func directory(for url: URL) throws -> URL {
        guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }
        let target = url.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isDirectory) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: target.path])
        }
        return isDirectory.boolValue ? target : target.deletingLastPathComponent()
    }
}
