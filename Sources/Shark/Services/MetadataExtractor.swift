import Foundation
import CryptoKit
import UniformTypeIdentifiers
import CoreGraphics
import ImageIO

public actor MetadataExtractor {
    public static let shared = MetadataExtractor()

    private init() {}

    public func extractMetadata(for url: URL) async -> FileMetadata? {
        let path = url.path
        var statBuf = stat()
        guard stat(path, &statBuf) == 0 else {
            return nil
        }

        let isDir = (statBuf.st_mode & S_IFMT) == S_IFDIR
        let size = isDir ? 0 : Int64(statBuf.st_size)
        let formattedSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)

        // POSIX Permissions
        let mode = statBuf.st_mode
        let octalString = String(format: "%04o", mode & 0o777)
        let symbolic = formatSymbolicPermissions(mode: mode, isDir: isDir)

        // Owner & Group
        let ownerName: String
        if let pw = getpwuid(statBuf.st_uid), let name = pw.pointee.pw_name {
            ownerName = String(cString: name)
        } else {
            ownerName = "\(statBuf.st_uid)"
        }

        let groupName: String
        if let gr = getgrgid(statBuf.st_gid), let name = gr.pointee.gr_name {
            groupName = String(cString: name)
        } else {
            groupName = "\(statBuf.st_gid)"
        }

        // Dates
        let created = Date(timeIntervalSince1970: TimeInterval(statBuf.st_birthtimespec.tv_sec))
        let modified = Date(timeIntervalSince1970: TimeInterval(statBuf.st_mtimespec.tv_sec))
        let accessed = Date(timeIntervalSince1970: TimeInterval(statBuf.st_atimespec.tv_sec))

        // Content Type
        let utType = UTType(filenameExtension: url.pathExtension) ?? (isDir ? .folder : .content)
        let kindDescription = utType.localizedDescription ?? (isDir ? "Folder" : "Document")

        // Image Dimensions
        let imageDimensions = extractImageDimensions(for: url)

        return FileMetadata(
            url: url,
            name: url.lastPathComponent,
            fileSize: size,
            formattedSize: formattedSize,
            isDirectory: isDir,
            kindDescription: kindDescription,
            contentTypeIdentifier: utType.identifier,
            dateCreated: created,
            dateModified: modified,
            dateAccessed: accessed,
            posixPermissions: mode,
            symbolicPermissions: symbolic,
            octalPermissions: octalString,
            ownerName: ownerName,
            groupName: groupName,
            imageDimensions: imageDimensions
        )
    }

    @concurrent public nonisolated func computeSHA256(for url: URL) async -> String? {
        guard !Task.isCancelled else { return nil }
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? fileHandle.close() }

        var hasher = SHA256()
        while true {
            guard !Task.isCancelled else { return nil }
            let data = fileHandle.readData(ofLength: 64 * 1024)
            if data.isEmpty { break }
            hasher.update(data: data)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func extractImageDimensions(for url: URL) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }
        if let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
           let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
            return CGSize(width: width, height: height)
        }
        return nil
    }

    private func formatSymbolicPermissions(mode: mode_t, isDir: Bool) -> String {
        var str = isDir ? "d" : "-"

        // User
        str += (mode & S_IRUSR) != 0 ? "r" : "-"
        str += (mode & S_IWUSR) != 0 ? "w" : "-"
        str += (mode & S_IXUSR) != 0 ? "x" : "-"

        // Group
        str += (mode & S_IRGRP) != 0 ? "r" : "-"
        str += (mode & S_IWGRP) != 0 ? "w" : "-"
        str += (mode & S_IXGRP) != 0 ? "x" : "-"

        // Others
        str += (mode & S_IROTH) != 0 ? "r" : "-"
        str += (mode & S_IWOTH) != 0 ? "w" : "-"
        str += (mode & S_IXOTH) != 0 ? "x" : "-"

        return str
    }
}
