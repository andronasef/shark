import Foundation

/// A rename that changes or removes a file's extension. Folders, dotfiles, adding an extension to a
/// file that had none, and case-only changes ("JPG" to "jpg") are not extension changes.
public struct ExtensionChange: Equatable, Sendable {
    public let oldExtension: String
    /// Empty when the new name has no extension.
    public let newExtension: String
    /// The typed name with the old extension added, for "Keep".
    public let keepingName: String

    public var isRemoval: Bool { newExtension.isEmpty }

    public static func check(oldName: String, newName: String, isFolder: Bool) -> ExtensionChange? {
        guard !isFolder else { return nil }
        let old = (oldName as NSString).pathExtension
        guard !old.isEmpty else { return nil }
        let new = (newName as NSString).pathExtension
        guard new.caseInsensitiveCompare(old) != .orderedSame else { return nil }
        // "report.txt" renamed to "report.txt.bak" keeps nothing; only the last extension counts.
        return ExtensionChange(oldExtension: old, newExtension: new, keepingName: newName + "." + old)
    }
}
