import SwiftUI

/// One owner for each custom glass surface; the surrounding toolbar background is hidden.
struct FinderGlassModifier: ViewModifier {
    var enabled = true
    var isSelected = false
    var interactive = true
    @AppStorage("liquidGlassTranslucency") private var translucency = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else if !translucency || reduceTransparency || contrast == .increased {
            content
                .background(Color(nsColor: isSelected ? .selectedControlColor : .controlBackgroundColor), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.25), lineWidth: 0.75))
        } else {
            glassOrMaterial(content)
        }
    }

    @ViewBuilder
    private func glassOrMaterial(_ content: Content) -> some View {
#if compiler(>=6.2)
        if #available(macOS 26, *) {
            content.glassEffect(
                .regular.tint(isSelected ? Color.primary.opacity(0.14) : nil).interactive(interactive),
                in: Capsule()
            )
        } else {
            fallbackMaterial(content)
        }
#else
        fallbackMaterial(content)
#endif
    }

    private func fallbackMaterial(_ content: Content) -> some View {
        content
            .background(.thinMaterial, in: Capsule())
            .background(isSelected ? Color.primary.opacity(0.12) : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.14), lineWidth: 0.75))
    }
}

extension View {
    func finderGlass(isSelected: Bool = false, interactive: Bool = true, enabled: Bool = true) -> some View {
        modifier(FinderGlassModifier(enabled: enabled, isSelected: isSelected, interactive: interactive))
    }

    @ViewBuilder
    func finderGlassContainer() -> some View {
#if compiler(>=6.2)
        if #available(macOS 26, *) {
            GlassEffectContainer(spacing: 6) { self }
        } else {
            self
        }
#else
        self
#endif
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder
    func finderChromeItem() -> some ToolbarContent {
#if compiler(>=6.2)
        if #available(macOS 26, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
#else
        self
#endif
    }
}

struct FinderToolbarCaption<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content
            Text(title)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
