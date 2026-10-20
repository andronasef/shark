import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SharkSettings.shared

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)

            tabsTab
                .tabItem {
                    Label("Tabs", systemImage: "rectangle.stack")
                }
                .tag(1)

            previewsTab
                .tabItem {
                    Label("Previews", systemImage: "eye")
                }
                .tag(2)
        }
        .frame(width: 480, height: 320)
        .padding(20)
    }

    private var generalTab: some View {
        Form {
            Section {
                Picker("Default View Mode:", selection: $settings.defaultViewMode) {
                    ForEach(DefaultViewModeSetting.allCases) { mode in
                        Text(mode.rawValue).tag(mode.rawValue)
                    }
                }

                Picker("New Windows Open With:", selection: $settings.startupLocation) {
                    ForEach(DefaultStartupLocation.allCases) { loc in
                        Text(loc.rawValue).tag(loc.rawValue)
                    }
                }

                Toggle("Show hidden files and dotfiles by default", isOn: $settings.showHiddenFilesByDefault)
                Toggle("Enable Liquid Glass translucency and vibrancy", isOn: $settings.liquidGlassTranslucency)
            }
        }
        .formStyle(.grouped)
    }

    private var tabsTab: some View {
        Form {
            Section {
                Toggle("Open new tabs at the far end of the strip", isOn: $settings.openNewTabsAtEnd)
                Toggle("Confirm before closing a window with multiple tabs", isOn: $settings.confirmBeforeClosingMultipleTabs)
            }
        }
        .formStyle(.grouped)
    }

    private var previewsTab: some View {
        Form {
            Section {
                Toggle("Enable hover quick-previews for images, text, video, and audio", isOn: $settings.hoverPreviewEnabled)

                if settings.hoverPreviewEnabled {
                    Toggle("Only preview while holding Shift", isOn: $settings.hoverPreviewRequiresShift)
                    Toggle("Auto-play video and audio previews", isOn: $settings.hoverPreviewAutoplay)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Hover Delay:")
                            Spacer()
                            Text("\(Int(settings.hoverPreviewDelayMs)) ms")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.hoverPreviewDelayMs, in: 150...1000, step: 50) {
                            Text("Hover Delay")
                        } minimumValueLabel: {
                            Text("Fast")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } maximumValueLabel: {
                            Text("Slow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Subfolder Tip") {
                Toggle("Show a drop-down arrow beside hovered folders", isOn: $settings.subfolderTipEnabled)
                Text("Click the arrow to browse everything inside a folder, to any depth, without leaving the current folder. Click an item to open it, ⌘-click to open a folder in a new tab, or ⌥-click to copy it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
