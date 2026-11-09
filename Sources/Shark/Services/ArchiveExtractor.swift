import Foundation
import os

public enum ArchiveError: LocalizedError, Equatable {
    case unsafePath(String)
    case empty(String)
    case unsupported(String)
    case failed(String, String)

    public var errorDescription: String? {
        switch self {
        case .unsafePath(let archive):
            return L10n.format("“%@” was not extracted because it contains items that would be written outside its folder.", L10n.literal(archive))
        case .empty(let archive):
            return L10n.format("“%@” is empty.", L10n.literal(archive))
        case .unsupported(let archive):
            return L10n.format("Shark can’t read “%@”.", L10n.literal(archive))
        case .failed(let archive, let reason):
            return L10n.format("“%@” couldn’t be extracted: %@", L10n.literal(archive), L10n.literal(reason))
        }
    }

    /// Archive Utility reads more formats and asks for passwords, so it is the fallback for these.
    public var offersArchiveUtility: Bool {
        switch self {
        case .unsupported: return true
        case .failed(_, let reason): return reason.localizedCaseInsensitiveContains("encrypt") || reason.localizedCaseInsensitiveContains("passphrase")
        default: return false
        }
    }
}

/// Unpacks archives next to themselves using the `bsdtar` that ships with macOS.
///
/// Everything is extracted into a private staging folder first. The archive's entry names are
/// checked before anything is written, so absolute and `..` paths never reach the disk, and
/// bsdtar itself refuses to write through a symbolic link. Only then is the result moved beside
/// the archive, through the same conflict choices as paste. Staging is always removed.
public enum ArchiveExtractor {
    static let tarExtensions: Set<String> = ["zip", "tar", "tgz", "tbz", "tbz2", "txz", "7z", "rar", "cpio", "gz", "bz2", "xz", "lzma"]
    static let archiveUtilityExtensions: Set<String> = ["sit", "sitx", "zipx"]
    private static let compoundSuffixes = [".tar.gz", ".tar.bz2", ".tar.xz", ".tar.lzma", ".tar.z"]

    public static func isArchive(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return tarExtensions.contains(ext) || archiveUtilityExtensions.contains(ext)
    }

    /// The folder name for an archive with several top-level items: "photos.tar.gz" → "photos".
    public static func baseName(of url: URL) -> String {
        let name = url.lastPathComponent
        let lower = name.lowercased()
        if let suffix = compoundSuffixes.first(where: { lower.hasSuffix($0) }) { return String(name.dropLast(suffix.count)) }
        return url.deletingPathExtension().lastPathComponent
    }

    /// Entry names that would leave the extraction folder.
    static func unsafeEntry(in listing: String) -> String? {
        for line in listing.split(separator: "\n", omittingEmptySubsequences: true) {
            let path = String(line)
            if path.hasPrefix("/") || path.split(separator: "/").contains("..") { return path }
        }
        return nil
    }

    /// Extracts `archive` beside itself. The result's actions are ready for one undo step.
    public static func extract(_ archive: URL, resolve: @escaping CollisionHandler) async throws -> TransferResult {
        let fileManager = FileManager.default
        let directory = archive.deletingLastPathComponent()
        let name = archive.lastPathComponent
        if archiveUtilityExtensions.contains(archive.pathExtension.lowercased()) { throw ArchiveError.unsupported(name) }

        let staging = directory.appendingPathComponent(".shark-extract-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: false)
        defer { try? fileManager.removeItem(at: staging) }

        let listing = staging.appendingPathComponent("listing.txt")
        let errors = staging.appendingPathComponent("errors.txt")
        func failure(_ status: Int32) -> ArchiveError {
            let text = (try? String(contentsOf: errors, encoding: .utf8)) ?? ""
            let reason = text.split(separator: "\n").first.map(String.init) ?? ""
            if reason.localizedCaseInsensitiveContains("Unrecognized archive format") { return .unsupported(name) }
            return .failed(name, reason.isEmpty ? L10n.format("tar failed with status %d", status) : reason)
        }

        let listStatus = try await run(["-tf", archive.path], output: listing, errors: errors)
        guard listStatus == 0 else { throw failure(listStatus) }
        let names = (try? String(contentsOf: listing, encoding: .utf8)) ?? ""
        if unsafeEntry(in: names) != nil { throw ArchiveError.unsafePath(name) }

        let payload = staging.appendingPathComponent("payload", isDirectory: true)
        try fileManager.createDirectory(at: payload, withIntermediateDirectories: false)
        let status = try await run(["-xf", archive.path, "-C", payload.path], output: nil, errors: errors)
        // bsdtar exits 1 when it cannot apply a Mac metadata entry (__MACOSX/._name) although every file
        // was written. That alone is not a failed extraction.
        let warnings = ((try? String(contentsOf: errors, encoding: .utf8)) ?? "").split(separator: "\n")
            .filter { !$0.contains("Error exit delayed") }  // bsdtar's own summary line
        let onlyMetadataWarnings = !warnings.isEmpty && warnings.allSatisfy { $0.localizedCaseInsensitiveContains("restore metadata") }
        guard status == 0 || onlyMetadataWarnings else { throw failure(status) }
        try Task.checkCancellation()

        // Archive Utility ignores these zip leftovers, and so do we.
        for junk in ["__MACOSX", ".DS_Store"] { try? fileManager.removeItem(at: payload.appendingPathComponent(junk)) }
        let children = try fileManager.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil, options: [])
        guard !children.isEmpty else { throw ArchiveError.empty(name) }
        let item: URL
        if children.count == 1 {
            item = children[0]
        } else {
            item = staging.appendingPathComponent(baseName(of: archive), isDirectory: true)
            try fileManager.moveItem(at: payload, to: item)
        }

        var result = await FileOperationsService.shared.transfer(items: [item], to: directory, mode: .move, resolve: resolve)
        // The moves came out of staging, so undo means "remove what was extracted", not "move back".
        result.actions = result.actions.compactMap { action in
            switch action {
            case .move(let pairs): return .create(urls: pairs.map(\.destination), name: L10n.text("Extract"))
            case .trash(let restorations) where restorations.contains(where: { $0.original.path.hasPrefix(staging.path) }): return nil
            default: return action
            }
        }
        return result
    }

    /// One bsdtar run. Output goes to files so a large listing can never fill a pipe and stall it.
    private static func run(_ arguments: [String], output: URL?, errors: URL) async throws -> Int32 {
        try Task.checkCancellation()
        let fileManager = FileManager.default
        func handle(_ url: URL?) throws -> FileHandle? {
            guard let url else { return nil }
            if !fileManager.fileExists(atPath: url.path) { fileManager.createFile(atPath: url.path, contents: nil) }
            let handle = try FileHandle(forWritingTo: url)
            try handle.truncate(atOffset: 0)
            return handle
        }
        let out = try handle(output), err = try handle(errors)
        defer { try? out?.close(); try? err?.close() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/bsdtar")
        process.arguments = arguments
        process.standardOutput = out ?? FileHandle.nullDevice
        process.standardError = err
        let runningPID = OSAllocatedUnfairLock<pid_t>(initialState: 0)
        let status: Int32 = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { process in
                    runningPID.withLock { $0 = 0 }
                    continuation.resume(returning: process.terminationStatus)
                }
                do {
                    try runningPID.withLock { pid in
                        try Task.checkCancellation()
                        try process.run()
                        pid = process.processIdentifier
                        if Task.isCancelled { kill(pid, SIGTERM) }
                    }
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                }
            }
        } onCancel: {
            runningPID.withLock { pid in if pid > 0 { kill(pid, SIGTERM) } }
        }
        try Task.checkCancellation()
        return status
    }
}
