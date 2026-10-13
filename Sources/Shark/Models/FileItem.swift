import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct FileItem: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let isPackage: Bool
    public let isHidden: Bool
    public let isSymlink: Bool
    public let isExecutable: Bool
    public let fileSize: Int64
    public let dateModified: Date
    public let dateCreated: Date
    public let kindDescription: String
    public let posixPermissions: Int
    public let ownerName: String
    public let groupName: String

    public init(
        url: URL,
        name: String,
        isDirectory: Bool,
        isPackage: Bool = false,
        isHidden: Bool = false,
        isSymlink: Bool = false,
        isExecutable: Bool = false,
        fileSize: Int64 = 0,
        dateModified: Date = Date(),
        dateCreated: Date = Date(),
        kindDescription: String = "",
        posixPermissions: Int = 0o644,
        ownerName: String = "",
        groupName: String = ""
    ) {
        self.url = url
        self.name = name
        self.isDirectory = isDirectory
        self.isPackage = isPackage
        self.isHidden = isHidden
        self.isSymlink = isSymlink
        self.isExecutable = isExecutable
        self.fileSize = fileSize
        self.dateModified = dateModified
        self.dateCreated = dateCreated
        self.kindDescription = kindDescription
        self.posixPermissions = posixPermissions
        self.ownerName = ownerName
        self.groupName = groupName
    }

    public var isNavigableDirectory: Bool {
        isDirectory && !isPackage
    }

    public var formattedSize: String {
        if isDirectory && !isPackage {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    public var permissionsString: String {
        let p = posixPermissions
        let isDir = isDirectory ? "d" : (isSymlink ? "l" : "-")
        let r1 = (p & 0o400) != 0 ? "r" : "-"
        let w1 = (p & 0o200) != 0 ? "w" : "-"
        let x1 = (p & 0o100) != 0 ? "x" : "-"
        let r2 = (p & 0o040) != 0 ? "r" : "-"
        let w2 = (p & 0o020) != 0 ? "w" : "-"
        let x2 = (p & 0o010) != 0 ? "x" : "-"
        let r3 = (p & 0o004) != 0 ? "r" : "-"
        let w3 = (p & 0o002) != 0 ? "w" : "-"
        let x3 = (p & 0o001) != 0 ? "x" : "-"
        return "\(isDir)\(r1)\(w1)\(x1)\(r2)\(w2)\(x2)\(r3)\(w3)\(x3)"
    }

    public var systemIconName: String {
        if isDirectory {
            if isPackage { return "shippingbox" }
            return "folder.fill"
        }
        if isSymlink { return "link" }
        
        let pathExt = url.pathExtension.lowercased()
        switch pathExt {
        case "swift", "c", "cpp", "h", "m", "mm", "rs", "go", "py", "js", "ts", "html", "css", "json", "yaml", "yml", "toml", "sh", "zsh":
            return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "gif", "webp", "tiff", "heic", "svg":
            return "photo"
        case "mp4", "mov", "mkv", "avi", "webm":
            return "film"
        case "mp3", "wav", "m4a", "flac", "aac", "ogg":
            return "waveform"
        case "zip", "tar", "gz", "bz2", "xz", "7z", "dmg":
            return "doc.zipper"
        case "pdf":
            return "doc.richtext"
        case "txt", "md", "rtf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}
