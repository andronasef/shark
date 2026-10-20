import SwiftUI

public struct BottomPathBarView: View {
    @Bindable var navigationState: NavigationState
    var workspace: WorkspaceState?

    public init(navigationState: NavigationState, workspace: WorkspaceState? = nil) {
        self.navigationState = navigationState
        self.workspace = workspace
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(segments, id: \.url) { seg in
                    Button(action: {
                        let isCmd = NSEvent.modifierFlags.contains(.command)
                        if isCmd, let workspace {
                            workspace.open(seg.url, from: navigationState, newTab: true)
                        } else {
                            navigationState.navigateTo(seg.url)
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: seg.isRoot ? "internaldrive" : (seg.isLast ? "folder.fill" : "folder"))
                                .font(.system(size: 11))
                                .foregroundColor(seg.isLast ? .accentColor : .secondary)
                            Text(seg.title)
                                .font(.system(size: 11, weight: seg.isLast ? .semibold : .regular))
                                .foregroundColor(seg.isLast ? .primary : .secondary)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 3)
                                .fill(seg.isLast ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Open in New Tab") {
                            workspace?.open(seg.url, from: navigationState, newTab: true)
                        }
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(seg.url.path, forType: .string)
                        }
                        Button("Open in Terminal") {
                            NSWorkspace.shared.open(seg.url)
                        }
                    }

                    if !seg.isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .frame(height: 22)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.4))
        .overlay(Divider(), alignment: .top)
    }

    private struct PathSeg {
        let title: String
        let url: URL
        let isRoot: Bool
        let isLast: Bool
    }

    private var segments: [PathSeg] {
        var ancestry: [URL] = []
        var cursor = navigationState.currentURL.standardizedFileURL
        while true {
            ancestry.append(cursor)
            let parent = cursor.deletingLastPathComponent()
            if parent.path == cursor.path || parent.path == "/" {
                if parent.path == "/" && cursor.path != "/" {
                    ancestry.append(parent)
                }
                break
            }
            cursor = parent
        }
        ancestry.reverse()

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
