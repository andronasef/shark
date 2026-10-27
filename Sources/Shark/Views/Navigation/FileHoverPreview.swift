import SwiftUI
import Observation

/// Owns one item's delayed preview; leaving or disabling it cancels pending work.
@MainActor
@Observable
final class HoverPreviewController {
    var isPresented = false
    @ObservationIgnored private var pending: Task<Void, Never>?

    /// How long a visible preview survives the pointer leaving its row, so the pointer can reach
    /// the preview itself (media controls need it).
    static let leaveGraceMilliseconds = 250.0

    func update(isHovering: Bool, enabled: Bool, url: URL, isDirectory: Bool, delayMilliseconds: Double,
                requireShift: Bool = false) {
        if isPresented, enabled {
            pending?.cancel()
            pending = nil
            if isHovering { return }
            pending = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(Self.leaveGraceMilliseconds))
                guard !Task.isCancelled, !HoverPreviewPanel.shared.isMouseInside else { return }
                self?.cancel()
            }
            return
        }
        cancel()
        guard isHovering, enabled, !isDirectory,
              HoverPreviewService.shared.supportsPreview(for: url) else { return }
        pending = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(max(0, delayMilliseconds)))
                // Shift can be pressed after the pointer is already resting on the row.
                while requireShift && !NSEvent.modifierFlags.contains(.shift) {
                    try await Task.sleep(for: .milliseconds(80))
                }
                self?.isPresented = true
            } catch { /* Hover ended before the preview appeared. */ }
        }
    }

    func cancel() {
        pending?.cancel()
        pending = nil
        isPresented = false
    }
}

private struct FileHoverPreviewModifier: ViewModifier {
    let item: FileItem
    let isRenaming: Bool
    @State private var isHovering = false
    // Created on first hover: most rows scroll past without ever owning a controller or settings observers.
    @State private var controller: HoverPreviewController?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
                if hovering, controller == nil { controller = HoverPreviewController() }
                updatePreview()
            }
            .onChange(of: isRenaming) { _, _ in updatePreview() }
            .onChange(of: item.url) { _, _ in controller?.cancel() }
            .simultaneousGesture(TapGesture().onEnded { controller?.cancel() })
            .onChange(of: controller?.isPresented ?? false) { _, presented in
                if presented {
                    HoverPreviewPanel.shared.show(item) { [controller] in controller?.cancel() }
                } else {
                    HoverPreviewPanel.shared.hide(ownerURL: item.url)
                }
            }
            .onDisappear {
                controller?.cancel()
                HoverPreviewPanel.shared.hide(ownerURL: item.url)
            }
    }

    private func updatePreview() {
        guard let controller else { return }
        let defaults = UserDefaults.standard
        let enabled = defaults.object(forKey: "hoverPreviewEnabled") as? Bool ?? true
        let delay = defaults.object(forKey: "hoverPreviewDelayMs") as? Double ?? 350
        let requiresShift = defaults.object(forKey: "hoverPreviewRequiresShift") as? Bool ?? false
        controller.update(isHovering: isHovering, enabled: enabled && !isRenaming,
                          url: item.url, isDirectory: item.isDirectory,
                          delayMilliseconds: delay, requireShift: requiresShift)
    }
}

extension View {
    func fileHoverPreview(_ item: FileItem, isRenaming: Bool = false) -> some View {
        modifier(FileHoverPreviewModifier(item: item, isRenaming: isRenaming))
    }
}
