import Foundation

public struct RenameRule: Sendable, Equatable {
    public enum PatternType: Sendable {
        case replace
        case addPrefixSuffix
        case formatWithIndex
    }

    public var findText: String
    public var replaceText: String
    public var prefix: String
    public var suffix: String
    public var useNumbering: Bool
    public var startingNumber: Int
    public var paddingDigits: Int

    public init(
        findText: String = "",
        replaceText: String = "",
        prefix: String = "",
        suffix: String = "",
        useNumbering: Bool = false,
        startingNumber: Int = 1,
        paddingDigits: Int = 2
    ) {
        self.findText = findText
        self.replaceText = replaceText
        self.prefix = prefix
        self.suffix = suffix
        self.useNumbering = useNumbering
        self.startingNumber = startingNumber
        self.paddingDigits = paddingDigits
    }

    public func apply(to filename: String, index: Int) -> String {
        let ext = (filename as NSString).pathExtension
        var base = (filename as NSString).deletingPathExtension

        if !findText.isEmpty {
            base = base.replacingOccurrences(of: findText, with: replaceText)
        }

        if !prefix.isEmpty {
            base = prefix + base
        }

        if !suffix.isEmpty {
            base = base + suffix
        }

        if useNumbering {
            let number = startingNumber + index
            let numStr = String(format: "%0\(paddingDigits)d", number)
            base = "\(base)_\(numStr)"
        }

        if ext.isEmpty {
            return base
        } else {
            return "\(base).\(ext)"
        }
    }
}

public actor FileOperationsService {
    public static let shared = FileOperationsService()

    private let fileManager = FileManager.default

    private init() {}

    public func createFolder(named name: String, at parent: URL) throws -> URL {
        let target = parent.appendingPathComponent(name, isDirectory: true)
        var destination = target
        var counter = 1

        while fileManager.fileExists(atPath: destination.path) {
            destination = parent.appendingPathComponent("\(name) \(counter)", isDirectory: true)
            counter += 1
        }

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        return destination
    }

    public func createFile(named name: String, at parent: URL, content: Data? = nil) throws -> URL {
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension

        var destination = parent.appendingPathComponent(name, isDirectory: false)
        var counter = 1

        while fileManager.fileExists(atPath: destination.path) {
            let newName = ext.isEmpty ? "\(base) \(counter)" : "\(base) \(counter).\(ext)"
            destination = parent.appendingPathComponent(newName, isDirectory: false)
            counter += 1
        }

        fileManager.createFile(atPath: destination.path, contents: content ?? Data(), attributes: nil)
        return destination
    }

    public func move(items: [URL], to destinationDir: URL) throws {
        for item in items {
            let destination = destinationDir.appendingPathComponent(item.lastPathComponent)
            try fileManager.moveItem(at: item, to: destination)
        }
    }

    public func copy(items: [URL], to destinationDir: URL) throws {
        for item in items {
            let filename = item.lastPathComponent
            var target = destinationDir.appendingPathComponent(filename)
            var counter = 1

            let ext = (filename as NSString).pathExtension
            let base = (filename as NSString).deletingPathExtension

            while fileManager.fileExists(atPath: target.path) {
                let newName = ext.isEmpty ? "\(base) copy \(counter)" : "\(base) copy \(counter).\(ext)"
                target = destinationDir.appendingPathComponent(newName)
                counter += 1
            }

            try fileManager.copyItem(at: item, to: target)
        }
    }

    public func duplicate(items: [URL]) throws {
        for item in items {
            let parent = item.deletingLastPathComponent()
            let filename = item.lastPathComponent
            let ext = (filename as NSString).pathExtension
            let base = (filename as NSString).deletingPathExtension

            var counter = 1
            var destination: URL
            repeat {
                let newName = ext.isEmpty ? "\(base) copy \(counter)" : "\(base) copy \(counter).\(ext)"
                destination = parent.appendingPathComponent(newName)
                counter += 1
            } while fileManager.fileExists(atPath: destination.path)

            try fileManager.copyItem(at: item, to: destination)
        }
    }

    public func rename(item: URL, to newName: String) throws -> URL {
        let parent = item.deletingLastPathComponent()
        let destination = parent.appendingPathComponent(newName)
        if item.path == destination.path { return item }
        try fileManager.moveItem(at: item, to: destination)
        return destination
    }

    public func trash(items: [URL]) throws {
        for item in items {
            try fileManager.trashItem(at: item, resultingItemURL: nil)
        }
    }

    public func deletePermanently(items: [URL]) throws {
        for item in items {
            try fileManager.removeItem(at: item)
        }
    }

    public func batchRename(items: [URL], rule: RenameRule) throws -> [URL] {
        var renamedURLs: [URL] = []
        for (index, item) in items.enumerated() {
            let currentName = item.lastPathComponent
            let newName = rule.apply(to: currentName, index: index)
            if currentName == newName {
                renamedURLs.append(item)
                continue
            }

            let destination = item.deletingLastPathComponent().appendingPathComponent(newName)
            try fileManager.moveItem(at: item, to: destination)
            renamedURLs.append(destination)
        }
        return renamedURLs
    }

    public func compress(items: [URL]) async throws -> URL {
        guard let first = items.first else {
            throw NSError(domain: "FileOperationsError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No items to compress"])
        }
        let parentDir = first.deletingLastPathComponent()
        let archiveName: String
        if items.count == 1 {
            archiveName = first.deletingPathExtension().lastPathComponent + ".zip"
        } else {
            archiveName = "Archive.zip"
        }

        var destination = parentDir.appendingPathComponent(archiveName)
        var counter = 1
        let archiveBase = (archiveName as NSString).deletingPathExtension
        while fileManager.fileExists(atPath: destination.path) {
            destination = parentDir.appendingPathComponent("\(archiveBase) \(counter).zip")
            counter += 1
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        var arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent"]
        for item in items {
            arguments.append(item.path)
        }
        arguments.append(destination.path)
        process.arguments = arguments

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw NSError(domain: "FileOperationsError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Compression failed with status \(process.terminationStatus)"])
        }
        return destination
    }
}
