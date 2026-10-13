import Foundation
import UniformTypeIdentifiers

public struct FileMetadata: Sendable, Identifiable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let fileSize: Int64
    public let formattedSize: String
    public let isDirectory: Bool
    public let kindDescription: String
    public let contentTypeIdentifier: String
    public let dateCreated: Date?
    public let dateModified: Date?
    public let dateAccessed: Date?
    public let posixPermissions: mode_t
    public let symbolicPermissions: String
    public let octalPermissions: String
    public let ownerName: String
    public let groupName: String
    public let imageDimensions: CGSize?
    public var sha256Hash: String?

    public init(
        url: URL,
        name: String,
        fileSize: Int64,
        formattedSize: String,
        isDirectory: Bool,
        kindDescription: String,
        contentTypeIdentifier: String,
        dateCreated: Date?,
        dateModified: Date?,
        dateAccessed: Date?,
        posixPermissions: mode_t,
        symbolicPermissions: String,
        octalPermissions: String,
        ownerName: String,
        groupName: String,
        imageDimensions: CGSize?,
        sha256Hash: String? = nil
    ) {
        self.url = url
        self.name = name
        self.fileSize = fileSize
        self.formattedSize = formattedSize
        self.isDirectory = isDirectory
        self.kindDescription = kindDescription
        self.contentTypeIdentifier = contentTypeIdentifier
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.dateAccessed = dateAccessed
        self.posixPermissions = posixPermissions
        self.symbolicPermissions = symbolicPermissions
        self.octalPermissions = octalPermissions
        self.ownerName = ownerName
        self.groupName = groupName
        self.imageDimensions = imageDimensions
        self.sha256Hash = sha256Hash
    }
}
