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
            title: L10n.text("Empty space in a folder"),
            summary: L10n.text("The blank area around and below the files, where nothing is under the pointer."),
            bindings: [
                HelpBinding(gesture: L10n.text("Double-click"), action: L10n.text("Go up one level. Open a folder, look around, double-click blank space to step back out.")),
                HelpBinding(gesture: L10n.text("Click"), action: L10n.text("Clear the selection.")),
                HelpBinding(gesture: L10n.text("Click and drag"), action: L10n.text("Draw a selection rectangle (icon view).")),
                HelpBinding(gesture: L10n.text("Right-click"), action: L10n.text("Folder menu: New Folder/File, Paste, Reload, Show Hidden Files, Open in Terminal, Copy Path.")),
            ]
        ),
        HelpZone(
            title: L10n.text("A file or folder"),
            summary: L10n.text("Pointing at an item."),
            bindings: [
                HelpBinding(gesture: L10n.text("Click / ⌘-click / ⇧-click"), action: L10n.text("Select an item, toggle an item, or extend the selection from the last clicked item.")),
                HelpBinding(gesture: L10n.text("Double-click"), action: L10n.text("Open it.")),
                HelpBinding(gesture: L10n.text("Middle-click a folder"), action: L10n.text("Open it in a new tab.")),
                HelpBinding(gesture: L10n.text("Hover a folder"), action: L10n.text("A drop-down arrow appears beside its name. Click it to browse everything inside, to any depth.")),
                HelpBinding(gesture: L10n.text("In the subfolder menu"), action: L10n.text("Click opens, ⌘-click opens a folder in a new tab, ⌥-click copies.")),
                HelpBinding(gesture: L10n.text("Hover a file"), action: L10n.text("After a short delay, a preview appears: images, text, video and audio with a seek bar, documents.")),
                HelpBinding(gesture: L10n.text("Hover + Shift"), action: L10n.text("Preview only while Shift is held (turn on in Settings › Previews).")),
                HelpBinding(gesture: L10n.text("Drag onto a folder"), action: L10n.text("Move it there, or copy it if the folder is on another disk. Hold ⌥ to copy, ⌘ to move.")),
                HelpBinding(gesture: L10n.text("Drag a selected item"), action: L10n.text("Carry the whole selection. Dragging an item that is not selected moves only that item.")),
                HelpBinding(gesture: L10n.text("Double-click an image"), action: L10n.text("Open it as usual, or in Shark Photo Viewer when that is switched on in Settings › Previews.")),
                HelpBinding(gesture: L10n.text("Right-click"), action: L10n.text("Item menu.")),
                HelpBinding(gesture: L10n.text("Right-click a selection"), action: L10n.text("Act on the whole selection when the item is part of it; otherwise only on the item.")),
            ]
        ),
        HelpZone(
            title: L10n.text("The terminal drawer"),
            summary: L10n.text("The shell below the files."),
            bindings: [
                HelpBinding(gesture: L10n.text("Click"), action: L10n.text("Give the keyboard to the shell. Click a file to return the arrow keys to the file list.")),
                HelpBinding(gesture: L10n.text("Drag the top edge"), action: L10n.text("Resize the drawer.")),
            ]
        ),
        HelpZone(
            title: L10n.text("A tab"),
            summary: L10n.text("Pointing at a tab in the strip."),
            bindings: [
                HelpBinding(gesture: L10n.text("Click"), action: L10n.text("Switch to the tab.")),
                HelpBinding(gesture: L10n.text("Middle-click"), action: L10n.text("Close the tab.")),
                HelpBinding(gesture: L10n.text("Double-click"), action: L10n.text("Pin or unpin the tab.")),
                HelpBinding(gesture: L10n.text("Drag"), action: L10n.text("Reorder tabs.")),
                HelpBinding(gesture: L10n.text("Right-click"), action: L10n.text("Tab menu: Duplicate, Pin, Lock, Colour, Close Others, Reopen Closed Tab.")),
            ]
        ),
        HelpZone(
            title: L10n.text("The tab strip"),
            summary: L10n.text("Anywhere over the row of tabs."),
            bindings: [
                HelpBinding(gesture: L10n.text("Scroll the wheel"), action: L10n.text("Cycle through tabs. Down is the next tab, up is the previous one.")),
                HelpBinding(gesture: L10n.text("Right-click the + button"), action: L10n.text("Tab Groups.")),
            ]
        ),
        HelpZone(
            title: L10n.text("Sidebar and path bar"),
            summary: L10n.text("The Places sidebar and the location capsule in the toolbar."),
            bindings: [
                HelpBinding(gesture: L10n.text("Middle-click a place or path segment"), action: L10n.text("Open it in a new tab.")),
                HelpBinding(gesture: L10n.text("⌘-click a path segment"), action: L10n.text("Open it in a new tab.")),
                HelpBinding(gesture: L10n.text("Click the arrow beside a path segment"), action: L10n.text("Browse that folder's subfolders.")),
            ]
        ),
        HelpZone(
            title: L10n.text("Anywhere in the window"),
            summary: L10n.text("Works wherever the pointer is."),
            bindings: [
                HelpBinding(gesture: L10n.text("Mouse side button (back)"), action: L10n.text("Go back in folder history.")),
                HelpBinding(gesture: L10n.text("Mouse side button (forward)"), action: L10n.text("Go forward in folder history.")),
                HelpBinding(gesture: L10n.text("⌃ + side button"), action: L10n.text("Previous or next tab.")),
                HelpBinding(gesture: L10n.text("⌘ + scroll wheel"), action: L10n.text("Make icons larger or smaller.")),
            ]
        ),
    ]
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("Explore Shark"))
                        .font(.title3.weight(.semibold))
                    Link(L10n.text("All Features"), destination: AppLinks.features)
                    Text(L10n.text("Browse the complete features list, including shortcuts and settings, on the Shark website. You can also find it in Help → All Features."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("Mouse"))
                        .font(.largeTitle.bold())
                    Text(L10n.text("What a click or scroll does depends on where the pointer is. Optional actions can be turned off in Settings › Mouse."))
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

                Divider()
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(L10n.text("Feature request or bug?"))
                            .foregroundStyle(.secondary)
                        Link(L10n.text("Tell us"), destination: AppLinks.feedback)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Link(L10n.text("Shark Website"), destination: AppLinks.website)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Link(L10n.text("GitHub"), destination: AppLinks.repository)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Link(L10n.text("Andrew Nasef"), destination: AppLinks.author)
                    }
                    .font(.callout)
                }
            }
            .padding(28)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 560, minHeight: 420)
    }
}
