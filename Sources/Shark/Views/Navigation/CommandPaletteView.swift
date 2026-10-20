import SwiftUI
import AppKit

public struct CommandPaletteView: View {
    @Bindable var workspace: WorkspaceState
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @State private var eventMonitor: Any?

    private var items: [CommandPaletteItem] {
        CommandPaletteService.shared.filter(query: query, for: workspace)
    }

    public init(workspace: WorkspaceState) {
        self.workspace = workspace
    }

    public var body: some View {
        ZStack {
            // Dismiss backdrop
            Color.black.opacity(0.32)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Floating Palette Card
            VStack(spacing: 0) {
                // Search Input Header
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    CommandPaletteSearchField(text: $query, onEscape: { dismiss() })
                        .frame(height: 28)

                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("esc")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.18))
                        )
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Results List
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "questionmark.folder")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No matching commands or places")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: 180)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                    paletteRow(item: item, isSelected: index == selectedIndex)
                                        .id(index)
                                        .onTapGesture {
                                            execute(item)
                                        }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                        }
                        .frame(maxHeight: 340)
                        .onChange(of: selectedIndex) { _, newIndex in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }

                Divider()

                // Footer Hints
                HStack {
                    Text("\(items.count) result\(items.count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        Label("Navigate", systemImage: "arrow.up.and.down")
                        Label("Select", systemImage: "return")
                        Label("Close", systemImage: "escape")
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.02))
            }
            .frame(width: 580)
            .background(
                LiquidGlassView(material: .popover, blendingMode: .withinWindow)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 12)
            .offset(y: -40)
        }
        .onAppear {
            installEventMonitor()
            selectedIndex = 0
        }
        .onDisappear {
            removeEventMonitor()
        }
        .onChange(of: query) { _, _ in
            selectedIndex = 0
        }
    }

    @ViewBuilder
    private func paletteRow(item: CommandPaletteItem, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.iconName)
                .font(.system(size: 14))
                .frame(width: 22, height: 22)
                .foregroundColor(isSelected ? .white : .accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let shortcut = item.shortcut {
                Text(shortcut)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.secondary.opacity(0.12))
                    )
                    .foregroundColor(isSelected ? .white : .secondary)
            } else {
                Text(item.category.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? Color.white.opacity(0.7) : Color.secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }

    private func execute(_ item: CommandPaletteItem) {
        dismiss()
        item.action()
    }

    private func dismiss() {
        workspace.isCommandPalettePresented = false
    }

    private func installEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Arrow Down
            if event.keyCode == 125 {
                let count = self.items.count
                if count > 0 {
                    self.selectedIndex = min(count - 1, self.selectedIndex + 1)
                }
                return nil
            }
            // Arrow Up
            if event.keyCode == 126 {
                let count = self.items.count
                if count > 0 {
                    self.selectedIndex = max(0, self.selectedIndex - 1)
                }
                return nil
            }
            // Return / Enter
            if event.keyCode == 36 {
                let count = self.items.count
                if count > 0 && self.selectedIndex >= 0 && self.selectedIndex < count {
                    let item = self.items[self.selectedIndex]
                    self.execute(item)
                }
                return nil
            }
            // Escape
            if event.keyCode == 53 {
                self.dismiss()
                return nil
            }
            return event
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

/// Custom AppKit textfield wrapper that auto-focuses on appearance
private struct CommandPaletteSearchField: NSViewRepresentable {
    @Binding var text: String
    var onEscape: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.placeholderString = "Type a command, folder, or path..."
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.delegate = context.coordinator

        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommandPaletteSearchField

        init(_ parent: CommandPaletteSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }
    }
}
