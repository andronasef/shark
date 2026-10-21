import SwiftUI

/// One mouse gesture and what it does.
struct HelpBinding: Identifiable {
    let gesture: String
    let action: String
    var id: String { gesture + action }
}

/// A place the pointer can be. The same gesture does different things in different zones.
struct HelpZone: Identifiable {
    let title: String
    let summary: String
    let bindings: [HelpBinding]
    var id: String { title }
}

/// The single source of truth for what the mouse does. Update this whenever a binding changes.
enum MouseHelp {
    static let zones: [HelpZone] = [
        HelpZone(
            title: "Empty space in a folder",
            summary: "The blank area around and below the files, where nothing is under the pointer.",
            bindings: [
                HelpBinding(gesture: "Double-click", action: "Go up one level. Open a folder, look around, double-click blank space to step back out."),
                HelpBinding(gesture: "Click", action: "Clear the selection."),
                HelpBinding(gesture: "Click and drag", action: "Draw a selection rectangle (icon view)."),
                HelpBinding(gesture: "Right-click", action: "Folder menu: New Folder/File, Paste, Reload, Show Hidden Files, Open in Terminal, Copy Path."),
            ]
        ),
        HelpZone(
            title: "A file or folder",
            summary: "Pointing at an item.",
            bindings: [
                HelpBinding(gesture: "Click / ⌘-click / ⇧-click", action: "Select an item, toggle an item, or extend the selection from the last clicked item."),
                HelpBinding(gesture: "Double-click", action: "Open it."),
                HelpBinding(gesture: "Middle-click a folder", action: "Open it in a new tab."),
                HelpBinding(gesture: "Hover a folder", action: "A drop-down arrow appears beside its name. Click it to browse everything inside, to any depth."),
                HelpBinding(gesture: "In the subfolder menu", action: "Click opens, ⌘-click opens a folder in a new tab, ⌥-click copies."),
                HelpBinding(gesture: "Hover a file", action: "After a short delay, a preview appears: images, text, video and audio with a seek bar, documents."),
                HelpBinding(gesture: "Hover + Shift", action: "Preview only while Shift is held (turn on in Settings › Previews)."),
                HelpBinding(gesture: "Drag onto a folder", action: "Move it there, or copy it if the folder is on another disk. Hold ⌥ to copy, ⌘ to move."),
                HelpBinding(gesture: "Right-click", action: "Item menu."),
            ]
        ),
        HelpZone(
            title: "A tab",
            summary: "Pointing at a tab in the strip.",
            bindings: [
                HelpBinding(gesture: "Click", action: "Switch to the tab."),
                HelpBinding(gesture: "Middle-click", action: "Close the tab."),
                HelpBinding(gesture: "Double-click", action: "Pin or unpin the tab."),
                HelpBinding(gesture: "Drag", action: "Reorder tabs."),
                HelpBinding(gesture: "Right-click", action: "Tab menu: Duplicate, Pin, Lock, Colour, Close Others, Reopen Closed Tab."),
            ]
        ),
        HelpZone(
            title: "The tab strip",
            summary: "Anywhere over the row of tabs.",
            bindings: [
                HelpBinding(gesture: "Scroll the wheel", action: "Cycle through tabs. Down is the next tab, up is the previous one."),
                HelpBinding(gesture: "Right-click the + button", action: "Tab Groups."),
            ]
        ),
        HelpZone(
            title: "Sidebar and path bar",
            summary: "The Places sidebar and the location capsule in the toolbar.",
            bindings: [
                HelpBinding(gesture: "Middle-click a place or path segment", action: "Open it in a new tab."),
                HelpBinding(gesture: "⌘-click a path segment", action: "Open it in a new tab."),
                HelpBinding(gesture: "Click the arrow beside a path segment", action: "Browse that folder's subfolders."),
            ]
        ),
        HelpZone(
            title: "Anywhere in the window",
            summary: "Works wherever the pointer is.",
            bindings: [
                HelpBinding(gesture: "Mouse side button (back)", action: "Go back in folder history."),
                HelpBinding(gesture: "Mouse side button (forward)", action: "Go forward in folder history."),
                HelpBinding(gesture: "⌃ + side button", action: "Previous or next tab."),
                HelpBinding(gesture: "⌘ + scroll wheel", action: "Make icons larger or smaller."),
            ]
        ),
    ]
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Mouse")
                        .font(.largeTitle.bold())
                    Text("What a click or scroll does depends on where the pointer is. Optional actions can be turned off in Settings › Mouse.")
                        .foregroundStyle(.secondary)
                }

                ForEach(MouseHelp.zones) { zone in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(zone.title).font(.title3.weight(.semibold))
                        Text(zone.summary).font(.callout).foregroundStyle(.secondary)
                        VStack(spacing: 0) {
                            ForEach(Array(zone.bindings.enumerated()), id: \.element.id) { index, binding in
                                HStack(alignment: .top, spacing: 16) {
                                    Text(binding.gesture)
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 190, alignment: .leading)
                                    Text(binding.action)
                                        .font(.system(size: 12))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 7)
                                .padding(.horizontal, 12)
                                if index < zone.bindings.count - 1 { Divider() }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 560, minHeight: 420)
    }
}
