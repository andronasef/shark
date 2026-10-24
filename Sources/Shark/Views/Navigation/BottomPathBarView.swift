import SwiftUI

public struct BottomPathBarView: View {
    @Bindable var navigationState: NavigationState
    var workspace: WorkspaceState?
    var inToolbar: Bool
    @FocusState private var isPathFocused: Bool

    public init(navigationState: NavigationState, workspace: WorkspaceState? = nil, inToolbar: Bool = false) {
        self.navigationState = navigationState
        self.workspace = workspace
        self.inToolbar = inToolbar
    }

    public var body: some View {
        Group {
            if inToolbar {
                pathContent
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .finderGlass(interactive: false)
            } else {
                pathContent
                    .frame(height: 22)
                    .liquidGlassBackground(material: .headerView)
                    .overlay(Divider(), alignment: .top)
            }
        }
        .onChange(of: navigationState.isEditingPath) { _, editing in
            if editing { isPathFocused = true }
        }
        .onAppear {
            if navigationState.isEditingPath { isPathFocused = true }
        }
    }

    @ViewBuilder
    private var pathContent: some View {
        if navigationState.isEditingPath {
            HStack(spacing: 6) {
                Image(systemName: "folder").foregroundStyle(.secondary)
                TextField(L10n.text("Go to folder"), text: $navigationState.pathInputText)
                    .environment(\.layoutDirection, .leftToRight)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isPathFocused)
                    .onAppear { isPathFocused = true }
                    .onSubmit { navigationState.commitPathInput() }
                    .onExitCommand { cancelEditing() }
                    .accessibilityLabel(L10n.text("Folder Path"))
                Button { cancelEditing() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.text("Cancel Path Editing"))
            }
            .padding(.horizontal, 10)
        } else {
            ScrollViewReader { proxy in
                breadcrumbs
                    .onAppear { proxy.scrollTo(navigationState.currentURL.standardizedFileURL, anchor: .trailing) }
                    .onChange(of: navigationState.currentURL) { _, url in
                        proxy.scrollTo(url.standardizedFileURL, anchor: .trailing)
                    }
            }
            .contextMenu {
                Button(L10n.text("Edit Path (⌘L)"), systemImage: "pencil") {
                    navigationState.pathInputText = navigationState.currentURL.path
                    navigationState.isEditingPath = true
                }
                Button(L10n.text("Copy Path"), systemImage: "link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(navigationState.currentURL.path, forType: .string)
                }
            }
        }
    }

    private func cancelEditing() {
        navigationState.isEditingPath = false
        navigationState.pathInputText = navigationState.currentURL.path
    }

    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(segments, id: \.url) { seg in
                    HStack(spacing: 2) {
                        Button(action: {
                            let isCmd = NSEvent.modifierFlags.contains(.command)
                            if isCmd, let workspace {
                                workspace.open(seg.url, from: navigationState, newTab: true)
                            } else {
                                navigationState.navigateTo(seg.url)
                            }
                        }) {
                            HStack(spacing: 3) {
                                if !inToolbar || seg.isRoot {
                                    Image(systemName: seg.isRoot ? "internaldrive" : (seg.isLast ? "folder.fill" : "folder"))
                                        .font(.system(size: 11))
                                        .frame(width: 14)
                                        .foregroundStyle(inToolbar ? Color.secondary : (seg.isLast ? Color.accentColor : Color.secondary))
                                }
                                Text(seg.title)
                                    .font(.system(size: inToolbar ? 12 : 11, weight: seg.isLast ? .semibold : .regular))
                                    .foregroundStyle(seg.isLast ? Color.primary : Color.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: inToolbar ? 180 : nil)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background {
                                if seg.isLast {
                                    if inToolbar {
                                        Capsule().fill(Color.primary.opacity(0.08))
                                    } else {
                                        RoundedRectangle(cornerRadius: 3).fill(Color.accentColor.opacity(0.12))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(seg.url.path)
                        .onMiddleClick {
                            workspace?.open(seg.url, from: navigationState, newTab: true)
                        }
                        .contextMenu {
                            Button(L10n.text("Open in New Tab"), systemImage: "plus.rectangle.on.rectangle") {
                                workspace?.open(seg.url, from: navigationState, newTab: true)
                            }
                            Button(L10n.text("Copy Path"), systemImage: "link") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(seg.url.path, forType: .string)
                            }
                            TerminalMenuItems(url: seg.url, workspace: workspace, source: navigationState)
                        }

                        // Cascading Subfolder Chevron Menu (QT-01)
                        CascadingFolderChevronButton(url: seg.url, symbol: inToolbar && !seg.isLast ? "chevron.right" : "chevron.down",
                                                    pointSize: inToolbar ? 7 : 8,
                                                    weight: inToolbar ? .medium : .bold,
                                                    tint: inToolbar ? .tertiaryLabelColor : .labelColor) { targetURL, inNewTab in
                            if inNewTab, let workspace {
                                workspace.open(targetURL, from: navigationState, newTab: true)
                            } else {
                                navigationState.navigateTo(targetURL)
                            }
                        }
                        .frame(width: inToolbar ? 16 : 10, height: inToolbar ? 22 : 14)
                    }
                    .id(seg.url)

                    if !inToolbar && !seg.isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
    }

    private struct PathSeg {
        let title: String
        let url: URL
        let isRoot: Bool
        let isLast: Bool
    }

    private var segments: [PathSeg] {
        let ancestry = navigationState.currentURL.ancestorChain

        return ancestry.enumerated().map { index, url in
            let isRoot = index == 0
            let isLast = index == ancestry.count - 1
            let title: String
            if url.path == "/" {
                title = "Macintosh HD"
            } else if url.path == FileManager.default.homeDirectoryForCurrentUser.path {
                title = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
            } else {
                title = url.lastPathComponent
            }
            return PathSeg(title: title, url: url, isRoot: isRoot, isLast: isLast)
        }
    }
}
