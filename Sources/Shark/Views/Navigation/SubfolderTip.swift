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
    @AppStorage("subfolderTipEnabled") private var enabled = true

    var body: some View {
        if enabled, isHovering, item.isNavigableDirectory {
            CascadingFolderChevronButton(url: item.url, pointSize: size * 0.5, onNavigate: onNavigate)
                .frame(width: size, height: size)
                .background(Circle().fill(.regularMaterial))
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
    }
}
