import SwiftUI

public struct BreadcrumbBarView: View {
    @Bindable var navigationState: NavigationState
    var workspace: WorkspaceState?
    @FocusState private var isFieldFocused: Bool

    public init(navigationState: NavigationState, workspace: WorkspaceState? = nil) {
        self.navigationState = navigationState
        self.workspace = workspace
    }

    public var body: some View {
        HStack(spacing: 4) {
            if navigationState.isEditingPath {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)

                    TextField("Path (e.g. ~/Documents or /Users)", text: $navigationState.pathInputText)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .monospaced))
                        .focused($isFieldFocused)
                        .onSubmit {
                            navigationState.commitPathInput()
                        }
                        .onExitCommand {
                            navigationState.isEditingPath = false
                            navigationState.pathInputText = navigationState.currentURL.path
                        }

                    Button(action: {
                        navigationState.commitPathInput()
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        navigationState.isEditingPath = false
                        navigationState.pathInputText = navigationState.currentURL.path
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                )
                .onAppear {
                    isFieldFocused = true
                }
            } else {
                HStack(spacing: 2) {
                    ForEach(pathSegments, id: \.url) { segment in
                        HStack(spacing: 2) {
                            Button(action: {
                                navigationState.navigateTo(segment.url)
                            }) {
                                HStack(spacing: 2) {
                                    if segment.isRoot {
                                        Image(systemName: "internaldrive")
                                            .font(.caption)
                                    }
                                    Text(segment.title)
                                        .font(.system(size: 12, weight: segment.isLast ? .semibold : .regular))
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(segment.isLast ? Color.accentColor.opacity(0.15) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)

                            // Cascading Subfolder Chevron Menu (QT-01)
                            CascadingFolderChevronButton(url: segment.url) { targetURL, inNewTab in
                                if inNewTab, let workspace {
                                    workspace.open(targetURL, from: navigationState, newTab: true)
                                } else {
                                    navigationState.navigateTo(targetURL)
                                }
                            }
                            .frame(width: 10, height: 14)
                        }

                        if !segment.isLast {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )
                .clipped()
                .onTapGesture(count: 2) {
                    navigationState.pathInputText = navigationState.currentURL.path
                    navigationState.isEditingPath = true
                }

                Button(action: {
                    navigationState.pathInputText = navigationState.currentURL.path
                    navigationState.isEditingPath = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        )
                }
                .buttonStyle(.plain)
                .help("Edit Path (⌘L)")
            }
        }
        .onChange(of: navigationState.isEditingPath) { _, isEditing in
            if isEditing {
                isFieldFocused = true
            }
        }
    }

    private struct PathSegment {
        let title: String
        let url: URL
        let isRoot: Bool
        let isLast: Bool
    }

    private var pathSegments: [PathSegment] {
        var segments: [PathSegment] = []
        let hierarchy = navigationState.currentURL.ancestorChain

        for (index, url) in hierarchy.enumerated() {
            let isRoot = index == 0
            let isLast = index == hierarchy.count - 1

            let title: String
            if url.path == "/" {
                title = "Macintosh HD"
            } else if url.path == FileManager.default.homeDirectoryForCurrentUser.path {
                title = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
            } else {
                title = url.lastPathComponent
            }

            segments.append(PathSegment(title: title, url: url, isRoot: isRoot, isLast: isLast))
        }

        return segments
    }
}
