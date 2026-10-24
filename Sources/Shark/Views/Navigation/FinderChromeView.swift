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
        content
            .accessibilityLabel(L10n.text(title))
    }
}

struct FinderToolbarSymbol: View {
    let symbol: String
    var disclosure = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .regular))
            if disclosure {
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .semibold))
            }
        }
        // Explicit, so the Customize Toolbar palette doesn't render the symbols in its dimmed default.
        .foregroundStyle(.primary)
        .frame(width: disclosure ? 42 : 30, height: 28)
        .contentShape(Capsule())
    }
}

struct FinderSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField(L10n.text("Search"), text: $text)
                .environment(\.layoutDirection, .leftToRight)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .accessibilityLabel(L10n.text("Search files in current folder"))
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("Clear Search"))
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 200, height: 28)
        .finderGlass(interactive: false)
    }
}

// Keep customization conformance through the macOS 26 glass modifier.
extension CustomizableToolbarContent {
    @ToolbarContentBuilder
    func customizableFinderChromeItem() -> some CustomizableToolbarContent {
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
