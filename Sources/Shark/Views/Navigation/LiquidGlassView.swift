import AppKit
import SwiftUI

public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State

    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

public struct LiquidGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var material: NSVisualEffectView.Material

    public init(cornerRadius: CGFloat = 10, material: NSVisualEffectView.Material = .popover) {
        self.cornerRadius = cornerRadius
        self.material = material
    }

    public func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBlur(material: material, blendingMode: .withinWindow)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

public extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 10, material: NSVisualEffectView.Material = .popover) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, material: material))
    }

    func liquidGlassBackground(material: NSVisualEffectView.Material = .sidebar, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) -> some View {
        background(VisualEffectBlur(material: material, blendingMode: blendingMode))
    }
}

public struct LiquidGlassView: View {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material = .popover, blendingMode: NSVisualEffectView.BlendingMode = .withinWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public var body: some View {
        VisualEffectBlur(material: material, blendingMode: blendingMode)
    }
}