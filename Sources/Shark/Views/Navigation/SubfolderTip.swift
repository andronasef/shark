import SwiftUI

/// Tracks the pointer over its content and hands the state to it, for controls that only
/// appear while a row is hovered.
struct HoverReveal<Content: View>: View {
    @State private var isHovering = false
    @ViewBuilder let content: (Bool) -> Content

    var body: some View {
        content(isHovering).onHover { isHovering = $0 }
    }
}

/// The "subfolder tip": a small drop-down arrow beside a hovered folder's name that opens a
/// cascading menu of everything inside it, to any depth.
struct SubfolderTip: View {
    let item: FileItem
    let isHovering: Bool
    var size: CGFloat = 18
    let onNavigate: (URL, Bool) -> Void

    var body: some View {
        // Read the setting only while hovering: an @AppStorage per row observes defaults for every row.
        if isHovering, item.isNavigableDirectory,
           UserDefaults.standard.object(forKey: "subfolderTipEnabled") as? Bool ?? true {
            // A SwiftUI button, not the AppKit chevron: an embedded NSView takes the pointer away
            // from the cell's hover tracking and the arrow would vanish as soon as it is reached.
            Button(action: showMenu) {
                Image(systemName: "chevron.down")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .frame(width: size, height: size)
                    .background(Circle().fill(.regularMaterial))
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(L10n.format("Browse subfolders of %@", L10n.literal(item.name)))
            .accessibilityLabel(L10n.format("Browse subfolders of %@", L10n.literal(item.name)))
        }
    }

    private func showMenu() {
        guard let event = NSApp.currentEvent, let view = event.window?.contentView else { return }
        // popUpContextMenu runs until the menu closes, so the builder (the menu's delegate) lives long enough.
        let builder = SubfolderMenuBuilder(onNavigate: onNavigate)
        NSMenu.popUpContextMenu(builder.buildMenu(for: item.url), with: event, for: view)
    }
}
