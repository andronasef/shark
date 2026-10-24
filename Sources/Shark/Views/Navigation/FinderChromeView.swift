import SwiftUI

/// One owner for each custom glass surface; the surrounding toolbar background is hidden.
struct FinderGlassModifier: ViewModifier {
    var enabled = true
    var isSelected = false
    var interactive = true
    @AppStorage("liquidGlassTranslucency") private var translucency = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if !enabled {
            content
        } else if !translucency || reduceTransparency || contrast == .increased {
            content
                .background(Color(nsColor: isSelected ? .selectedControlColor : .controlBackgroundColor), in: Capsule())
                .overlay(Capsule().strokeBorder(colorScheme == .dark ? Color.white.opacity(0.3) : Color.primary.opacity(0.25), lineWidth: 0.75))
        } else {
            glassOrMaterial(content)
        }
    }

    @ViewBuilder
    private func glassOrMaterial(_ content: Content) -> some View {
#if compiler(>=6.2)
        if #available(macOS 26, *) {
            content.glassEffect(
                .regular.tint(isSelected ? (colorScheme == .dark ? Color.white.opacity(0.18) : Color.primary.opacity(0.14)) : nil).interactive(interactive),
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
            .background(isSelected ? (colorScheme == .dark ? Color.white.opacity(0.18) : Color.primary.opacity(0.12)) : Color.clear, in: Capsule())
            .overlay(Capsule().strokeBorder(colorScheme == .dark ? Color.white.opacity(0.25) : Color.primary.opacity(0.14), lineWidth: 0.75))
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
    let namesItem: Bool
    @ViewBuilder let content: Content

    /// `namesItem: false` for a control that shares a toolbar item with a more descriptive one.
    init(_ title: String, namesItem: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.namesItem = namesItem
        self.content = content()
    }

    var body: some View {
        if namesItem {
            // SwiftUI names customizable toolbar items (palette and "Icon and Text") from a Label's title.
            Label { Text(L10n.text(title)) } icon: { content }
                .labelStyle(.iconOnly)
                .accessibilityLabel(L10n.text(title))
        } else {
            content.accessibilityLabel(L10n.text(title))
        }
    }
}

struct FinderToolbarSymbol: View {
    let symbol: String
    var disclosure = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .regular))
            if disclosure {
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .semibold))
            }
        }
        // Explicit high contrast so Customize Toolbar palette and dark mode sheets never render dim symbols.
        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.9) : Color.primary)
        .frame(width: disclosure ? 42 : 30, height: 28)
        .contentShape(Capsule())
    }
}

struct FinderSearchField: View {
    @Binding var text: String
    var focusRequest = 0
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.75) : Color.secondary)
            TextField(L10n.text("Search"), text: $text)
                .environment(\.layoutDirection, .leftToRight)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.95) : Color.primary)
                .accessibilityLabel(L10n.text("Search files in current folder"))
                .focused($focused)
                .onChange(of: focusRequest) { focused = true }
                .background(ToolbarFieldFocuser(request: focusRequest, onAppear: false))
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.75) : Color.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("Clear Search"))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
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

/// SwiftUI focus requests don't reach a toolbar item while another hosting view (such as the
/// sidebar) holds AppKit focus, so ⌘L/⌘F would show or target a field without moving the
/// keyboard into it. This makes the neighbouring AppKit text field the first responder when it
/// appears (if `onAppear`) and whenever `request` changes.
struct ToolbarFieldFocuser: NSViewRepresentable {
    var request: Int
    var onAppear = true

    func makeNSView(context: Context) -> Probe {
        let probe = Probe()
        probe.focusOnWindow = onAppear
        probe.lastRequest = request
        return probe
    }

    func updateNSView(_ probe: Probe, context: Context) {
        guard request != probe.lastRequest else { return }
        probe.lastRequest = request
        probe.focusSoon()
    }

    final class Probe: NSView {
        var focusOnWindow = true
        var lastRequest = 0
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil && focusOnWindow { focusSoon() }
        }

        func focusSoon() {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window, let field = self.nearestTextField() else { return }
                if window.firstResponder !== field.currentEditor() { window.makeFirstResponder(field) }
            }
        }

        /// The field is a sibling in the same small hosting subtree; search a few levels up.
        private func nearestTextField() -> NSTextField? {
            var ancestor = superview
            for _ in 0..<6 {
                guard let current = ancestor else { return nil }
                if let field = Self.firstTextField(in: current) { return field }
                ancestor = current.superview
            }
            return nil
        }

        private static func firstTextField(in view: NSView) -> NSTextField? {
            for sub in view.subviews {
                if let field = sub as? NSTextField, field.isEditable { return field }
                if let found = firstTextField(in: sub) { return found }
            }
            return nil
        }
    }
}
