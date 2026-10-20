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
    let onNavigate: (URL, Bool) -> Void
    @AppStorage("subfolderTipEnabled") private var enabled = true

    var body: some View {
        if enabled, isHovering, item.isNavigableDirectory {
            CascadingFolderChevronButton(url: item.url, onNavigate: onNavigate)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.primary.opacity(0.12)))
        }
    }
}
