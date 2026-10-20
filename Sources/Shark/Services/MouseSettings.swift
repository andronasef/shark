import Foundation

/// The optional mouse behaviours. All default to on; Settings › Mouse turns each one off.
enum MouseSetting: String, CaseIterable {
    case marginDoubleClickUp
    case tabDoubleClickPin
    case sideButtons
    case tabStripScroll

    var key: String { "mouse.\(rawValue)" }

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
}
