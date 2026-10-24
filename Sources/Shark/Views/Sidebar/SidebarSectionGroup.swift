import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Persisted disclosure state is separate from temporary expansion during a drag.
struct SidebarSectionGroup<Content: View>: View {
    let title: String
    @AppStorage private var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState.Binding var focus: String?
    @State private var isHovered = false
    @State private var temporaryExpansion = false
    @State private var springTask: Task<Void, Never>?
    let onDropFolders: (([URL]) -> Bool)?
    let content: Content

    init(_ title: String, focus: FocusState<String?>.Binding,
         onDropFolders: (([URL]) -> Bool)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self._focus = focus
        self._isExpanded = AppStorage(wrappedValue: true, "sidebar.section.\(title).expanded")
        self.onDropFolders = onDropFolders
        self.content = content()
    }

    private var expanded: Bool { isExpanded || temporaryExpansion }
    private var headerID: String { "\(title):header" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { focus = headerID; setExpanded(!expanded) } label: {
                HStack {
                    Text(L10n.text(title))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .opacity(isHovered || focus == headerID ? 1 : 0.55)
                        .accessibilityHidden(true)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(isHovered ? 0.05 : 0)))
                .overlay {
                    if focus == headerID {
                        RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 1.5)
                    }
                }
            }
            .buttonStyle(.plain)
            .focusable()
            .focusEffectDisabled()
            .focused($focus, equals: headerID)
            .onHover { isHovered = $0 }
            .onKeyPress(.rightArrow) { setExpanded(true); return .handled }
            .onKeyPress(.leftArrow) { setExpanded(false); return .handled }
            .onKeyPress(.return) { setExpanded(!expanded); return .handled }
            .onKeyPress(.space) { setExpanded(!expanded); return .handled }
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(L10n.text(title))
            .accessibilityValue(L10n.text(expanded ? "Expanded" : "Collapsed"))
            .help(expanded ? L10n.format("Collapse %@", L10n.text(title)) : L10n.format("Expand %@", L10n.text(title)))
            if expanded {
                content
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: expanded)
        .padding(.top, 14)
        .onDrop(of: [UTType.sharkFavorite, UTType.fileURL], delegate: SidebarSectionDropDelegate(
            allowsDrop: onDropFolders != nil,
            entered: {
                guard !expanded else { return }
                springTask?.cancel()
                springTask = Task {
                    do {
                        try await Task.sleep(for: .milliseconds(600))
                        guard !Task.isCancelled else { return }
                        temporaryExpansion = true
                    } catch {}
                }
            }, exited: resetSpringExpansion,
            dropped: { urls in
                let accepted = onDropFolders?(urls) ?? false
                if accepted { setExpanded(true) }
                return accepted
            }))
        .background(SidebarDragEndObserver(onEnd: resetSpringExpansion))
        .onDisappear { resetSpringExpansion() }
    }

    private func setExpanded(_ value: Bool) {
        if !value, focus?.hasPrefix("\(title):") == true { focus = headerID }
        springTask?.cancel()
        temporaryExpansion = false
        isExpanded = value
    }

    private func resetSpringExpansion() {
        springTask?.cancel()
        springTask = nil
        temporaryExpansion = false
    }
}

private struct SidebarSectionDropDelegate: DropDelegate {
    let allowsDrop: Bool
    let entered: () -> Void
    let exited: () -> Void
    let dropped: ([URL]) -> Bool

    func dropEntered(info: DropInfo) { entered() }
    func dropExited(info: DropInfo) { exited() }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: allowsDrop ? .copy : .forbidden) }
    func performDrop(info: DropInfo) -> Bool {
        guard allowsDrop else { exited(); return false }
        let providers = info.itemProviders(for: [UTType.sharkFavorite, UTType.fileURL])
        guard !providers.isEmpty else { return false }
        Task { @MainActor in
            let urls = await SidebarDropReader.urls(from: providers)
            _ = dropped(urls)
            exited()
        }
        return true
    }
}

/// Clears spring expansion even when a drag is cancelled without a drop.
private struct SidebarDragEndObserver: NSViewRepresentable {
    let onEnd: () -> Void
    func makeNSView(context: Context) -> DragEndView { let view = DragEndView(); view.onEnd = onEnd; return view }
    func updateNSView(_ view: DragEndView, context: Context) { view.onEnd = onEnd }
    static func dismantleNSView(_ view: DragEndView, coordinator: ()) { view.stop() }

    final class DragEndView: NSView {
        var onEnd: (() -> Void)?
        var monitor: Any?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .keyDown]) { [weak self] event in
                guard let self, event.window === self.window else { return event }
                if event.type == .leftMouseUp || event.keyCode == 53 {
                    DispatchQueue.main.async { [weak self] in self?.onEnd?() }
                }
                return event
            }
        }
        func stop() { if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil } }
    }
}
