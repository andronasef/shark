import SwiftUI

public struct BreadcrumbBarView: View {
    @Bindable var navigationState: NavigationState
    @FocusState private var isFieldFocused: Bool

    public init(navigationState: NavigationState) {
        self.navigationState = navigationState
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(pathSegments, id: \.url) { segment in
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

                            if !segment.isLast {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                )

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
    }

    private struct PathSegment {
        let title: String
        let url: URL
        let isRoot: Bool
        let isLast: Bool
    }

    private var pathSegments: [PathSegment] {
        var segments: [PathSegment] = []
        let current = navigationState.currentURL.standardizedFileURL

        var ancestry: [URL] = []
        var cursor = current
        while true {
            ancestry.append(cursor)
            let parent = cursor.deletingLastPathComponent()
            if parent.path == cursor.path {
                break
            }
            cursor = parent
        }

        let orderedAncestors = ancestry.reversed()
        let count = orderedAncestors.count

        for (index, url) in orderedAncestors.enumerated() {
            let isRoot = (index == 0)
            let isLast = (index == count - 1)
            let title = isRoot ? "Macintosh HD" : url.lastPathComponent
            segments.append(PathSegment(title: title, url: url, isRoot: isRoot, isLast: isLast))
        }

        return segments
    }
}
