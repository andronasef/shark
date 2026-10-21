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

            MouseSettingsTab()
                .tabItem {
                    Label("Mouse", systemImage: "computermouse")
                }
                .tag(3)

            privacyTab
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }
                .tag(4)
        }
        .frame(width: 480, height: 420)
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

            Section("Updates") {
                Toggle("Automatically check for updates", isOn: $settings.automaticallyCheckForUpdates)
                Text("Shark checks once a day and only shows an alert. You can always use Shark › Check for Updates…")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("About & Feedback") {
                Link(destination: AppLinks.website) {
                    HStack {
                        Text("Shark Website")
                        Spacer()
                        Text("shark.andronasef.com")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: AppLinks.repository) {
                    HStack {
                        Text("Source Code")
                        Spacer()
                        Text("GitHub")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: AppLinks.feedback) {
                    HStack {
                        Text("Feedback & Feature Requests")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: AppLinks.author) {
                    HStack {
                        Text("Created by Andrew Nasef")
                        Spacer()
                        Text("andronasef.com")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
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

    private var privacyTab: some View {
        Form {
            Section("Analytics & Crash Reporting") {
                Toggle("Share anonymous usage statistics", isOn: $settings.isAnalyticsEnabled)
                    .onChange(of: settings.isAnalyticsEnabled) { _, newValue in
                        TelemetryService.shared.setAnalyticsEnabled(newValue)
                    }
                Text("Helps us improve Shark by sharing anonymous feature usage data. File names, folder paths, and terminal commands are never collected.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle("Send crash reports", isOn: $settings.isCrashReportingEnabled)
                    .onChange(of: settings.isCrashReportingEnabled) { _, newValue in
                        TelemetryService.shared.setCrashReportingEnabled(newValue)
                    }
                Text("Automatically sends crash diagnostics to Firebase Crashlytics to help us diagnose and fix issues.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct MouseSettingsTab: View {
    @AppStorage(MouseSetting.marginDoubleClickUp.key) private var marginUp = true
    @AppStorage(MouseSetting.tabDoubleClickPin.key) private var tabPin = true
    @AppStorage(MouseSetting.sideButtons.key) private var sideButtons = true
    @AppStorage(MouseSetting.tabStripScroll.key) private var tabScroll = true

    var body: some View {
        Form {
            Section("Folders") {
                Toggle("Double-click empty space to go up one level", isOn: $marginUp)
            }
            Section("Tabs") {
                Toggle("Double-click a tab to pin or unpin it", isOn: $tabPin)
                Toggle("Scroll over the tab strip to switch tabs", isOn: $tabScroll)
            }
            Section("Mouse buttons") {
                Toggle("Side buttons go back and forward (⌃ + side button switches tabs)", isOn: $sideButtons)
            }
            Text("All mouse actions are listed in Help › Shark Help.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .formStyle(.grouped)
    }
}
