import Foundation
import UniformTypeIdentifiers

public actor FileSystemService {
    public static let shared = FileSystemService()

    private let fileManager = FileManager.default

    public init() {}

    private let resourceKeys: Set<URLResourceKey> = [
        .nameKey,
        .isDirectoryKey,
        .isPackageKey,
        .isHiddenKey,
        .isSymbolicLinkKey,
        .isExecutableKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .creationDateKey,
        .localizedTypeDescriptionKey
    ]

    /// Reads directory contents asynchronously with pre-fetched resource keys for ultra-fast performance.
    public func contentsOfDirectory(at url: URL, showHidden: Bool = false) throws -> [FileItem] {
        let normalizedURL = url.standardizedFileURL.resolvingSymlinksInPath()
        
        let contents = try fileManager.contentsOfDirectory(
            at: normalizedURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: showHidden ? [] : [.skipsHiddenFiles]
        )

        var items: [FileItem] = []
        items.reserveCapacity(contents.count)

        for fileURL in contents {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
                let name = resourceValues.name ?? fileURL.lastPathComponent
                let isDirectory = resourceValues.isDirectory ?? false
                let isPackage = resourceValues.isPackage ?? false
                let isHidden = resourceValues.isHidden ?? false
                let isSymlink = resourceValues.isSymbolicLink ?? false
                let isExecutable = resourceValues.isExecutable ?? false
                let fileSize = Int64(resourceValues.fileSize ?? 0)
                let dateModified = resourceValues.contentModificationDate ?? Date()
                let dateCreated = resourceValues.creationDate ?? Date()
                let kindDescription = resourceValues.localizedTypeDescription ?? (isDirectory ? "Folder" : "File")

                // POSIX attributes
                var permissions = 0o644
                var ownerName = ""
                var groupName = ""

                if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path) {
                    if let posixNumber = attrs[.posixPermissions] as? NSNumber {
                        permissions = posixNumber.intValue
                    }
                    ownerName = attrs[.ownerAccountName] as? String ?? ""
                    groupName = attrs[.groupOwnerAccountName] as? String ?? ""
                }

                let item = FileItem(
                    url: fileURL,
                    name: name,
                    isDirectory: isDirectory,
                    isPackage: isPackage,
                    isHidden: isHidden,
                    isSymlink: isSymlink,
                    isExecutable: isExecutable,
                    fileSize: fileSize,
                    dateModified: dateModified,
                    dateCreated: dateCreated,
                    kindDescription: kindDescription,
                    posixPermissions: permissions,
                    ownerName: ownerName,
                    groupName: groupName
                )
                items.append(item)
            } catch {
                // If single file property retrieval fails, create basic item
                let item = FileItem(
                    url: fileURL,
                    name: fileURL.lastPathComponent,
                    isDirectory: (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                )
                items.append(item)
            }
        }

        return items
    }

    /// Returns standard macOS Places for sidebar navigation.
    public func standardPlaces() -> [SidebarItem] {
        var places: [SidebarItem] = []

        // Home
        let homeURL = fileManager.homeDirectoryForCurrentUser
        places.append(SidebarItem(
            name: "Home",
            url: homeURL,
            iconName: "house",
            section: .places
        ))

        // Desktop
        if let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first {
            places.append(SidebarItem(
                name: "Desktop",
                url: desktopURL,
                iconName: "menubar.dock.rectangle",
                section: .places
            ))
        }

        // Documents
        if let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            places.append(SidebarItem(
                name: "Documents",
                url: docsURL,
                iconName: "doc.text",
                section: .places
            ))
        }

        // Downloads
        if let downURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            places.append(SidebarItem(
                name: "Downloads",
                url: downURL,
                iconName: "arrow.down.circle",
                section: .places
            ))
        }

        // Applications
        if let appURL = fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first {
            places.append(SidebarItem(
                name: "Applications",
                url: appURL,
                iconName: "app.badge",
                section: .places
            ))
        }

        return places
    }

    /// Returns mounted filesystem volumes.
    public func mountedVolumes() -> [SidebarItem] {
        var volumeItems: [SidebarItem] = []

        let volumeKeys: [URLResourceKey] = [.volumeLocalizedNameKey, .isVolumeKey, .volumeIsRemovableKey]
        if let volumeURLs = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: volumeKeys, options: [.skipHiddenVolumes]) {
            for vURL in volumeURLs {
                let name = (try? vURL.resourceValues(forKeys: [.volumeLocalizedNameKey]).volumeLocalizedName) ?? vURL.lastPathComponent
                let isRemovable = (try? vURL.resourceValues(forKeys: [.volumeIsRemovableKey]).volumeIsRemovable) ?? false
                let icon = isRemovable ? "externaldrive.fill" : "internaldrive.fill"
                
                volumeItems.append(SidebarItem(
                    id: vURL.path,
                    name: name.isEmpty ? vURL.lastPathComponent : name,
                    url: vURL,
                    iconName: icon,
                    section: .volumes,
                    isRemovable: isRemovable
                ))
            }
        }

        // Fallback root volume if mountedVolumes list was empty
        if volumeItems.isEmpty {
            volumeItems.append(SidebarItem(
                id: "/",
                name: "Macintosh HD",
                url: URL(fileURLWithPath: "/"),
                iconName: "internaldrive.fill",
                section: .volumes
            ))
        }

        return volumeItems
    }

    /// Resolves user input paths (including ~ expansion and absolute paths).
    nonisolated public func resolvePath(_ rawPath: String) -> URL? {
        let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let expanded: String
        if trimmed == "~" {
            expanded = FileManager.default.homeDirectoryForCurrentUser.path
        } else if trimmed.hasPrefix("~/") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            expanded = home + String(trimmed.dropFirst())
        } else {
            expanded = trimmed
        }

        let url = URL(fileURLWithPath: expanded).standardizedFileURL
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
            return url
        }
        return nil
    }

    /// Returns parent directory if not already root.
    nonisolated public func parentDirectory(of url: URL) -> URL? {
        let standardized = url.standardizedFileURL
        guard standardized.path != "/" else { return nil }
        let parent = standardized.deletingLastPathComponent().standardizedFileURL
        if parent.path == standardized.path || parent.path == "/.." {
            return nil
        }
        return parent
    }
}
