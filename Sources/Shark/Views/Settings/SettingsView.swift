import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings = SharkSettings.shared
    @AppStorage(AppLocalization.preferenceKey) private var language = AppLanguage.system.rawValue
    @AppStorage("openImagesInShark") private var openImagesInShark = false
    @AppStorage(SidebarStyle.storageKey) private var sidebarStyle = SidebarStyle.places.rawValue

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label(L10n.text("General"), systemImage: "gearshape")
                }
                .tag(0)

            tabsTab
                .tabItem {
                    Label(L10n.text("Tabs"), systemImage: "rectangle.stack")
                }
                .tag(1)

            previewsTab
                .tabItem {
                    Label(L10n.text("Previews"), systemImage: "eye")
                }
                .tag(2)

            MouseSettingsTab()
                .tabItem {
                    Label(L10n.text("Mouse"), systemImage: "computermouse")
                }
                .tag(3)

            privacyTab
                .tabItem {
                    Label(L10n.text("Privacy"), systemImage: "hand.raised")
                }
                .tag(4)
        }
        .frame(width: 480, height: 420)
        .padding(20)
    }

    private var generalTab: some View {
        Form {
            Section(L10n.text("Language")) {
                Picker(L10n.text("App Language:"), selection: $language) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .onChange(of: language) { oldVal, newVal in
                    guard oldVal != newVal else { return }
                    AppLocalization.updateProcessArguments()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        AppLocalization.relaunchApp()
                    }
                }

                HStack {
                    Text(L10n.text("Restart Shark to apply the selected language."))
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button(L10n.text("Restart")) {
                        AppLocalization.relaunchApp()
                    }
                    .controlSize(.small)
                }
            }
            Section(L10n.text("Sidebar")) {
                Picker(L10n.text("Sidebar Style:"), selection: $sidebarStyle) {
                    ForEach(SidebarStyle.allCases) { style in
                        Text(style.displayName).tag(style.rawValue)
                    }
                }
                Text(L10n.text("Folder Tree shows an expandable list of folders, like File Explorer, in place of Locations and Tags."))
                    .font(.caption).foregroundColor(.secondary)
            }
            Section {
                Picker(L10n.text("Default View Mode:"), selection: $settings.defaultViewMode) {
                    ForEach(DefaultViewModeSetting.allCases) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }

                Picker(L10n.text("New Windows Open With:"), selection: $settings.startupLocation) {
                    ForEach(DefaultStartupLocation.allCases) { loc in
                        Text(loc.displayName).tag(loc.rawValue)
                    }
                }

                Toggle(L10n.text("Show hidden files and dotfiles by default"), isOn: $settings.showHiddenFilesByDefault)
                Toggle(L10n.text("Enable Liquid Glass translucency and vibrancy"), isOn: $settings.liquidGlassTranslucency)
            }

            Section(L10n.text("Default Folder App")) {
                DefaultFolderAppControls(allowsRestore: true)
            }

            Section(L10n.text("Updates")) {
                Toggle(L10n.text("Automatically check for updates"), isOn: $settings.automaticallyCheckForUpdates)
                Text(L10n.text("Shark checks once a day and only shows an alert. You can always use Shark › Check for Updates…"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(L10n.text("About & Feedback")) {
                Link(destination: AppLinks.website) {
                    HStack {
                        Text(L10n.text("Shark Website"))
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
                        Text(L10n.text("Source Code"))
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
                        Text(L10n.text("Feedback & Feature Requests"))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Link(destination: AppLinks.author) {
                    HStack {
                        Text(L10n.text("Created by Andrew Nasef"))
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
                Toggle(L10n.text("Open new tabs at the far end of the strip"), isOn: $settings.openNewTabsAtEnd)
                Toggle(L10n.text("Confirm before closing a window with multiple tabs"), isOn: $settings.confirmBeforeClosingMultipleTabs)
            }
        }
        .formStyle(.grouped)
    }

    private var previewsTab: some View {
        Form {
            Section(L10n.text("Photo Viewer")) {
                Toggle(L10n.text("Open images in Shark Photo Viewer on double-click"), isOn: $openImagesInShark)
                Text(L10n.text("Space continues to open Quick Look. You can always open the photo viewer from an image’s context menu."))
                    .font(.caption).foregroundColor(.secondary)
            }
            Section {
                Toggle(L10n.text("Enable hover quick-previews for images, text, video, and audio"), isOn: $settings.hoverPreviewEnabled)

                if settings.hoverPreviewEnabled {
                    Toggle(L10n.text("Only preview while holding Shift"), isOn: $settings.hoverPreviewRequiresShift)
                    Toggle(L10n.text("Auto-play video and audio previews"), isOn: $settings.hoverPreviewAutoplay)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(L10n.text("Hover Delay:"))
                            Spacer()
                            Text("\(Int(settings.hoverPreviewDelayMs)) ms")
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.hoverPreviewDelayMs, in: 150...1000, step: 50) {
                            Text(L10n.text("Hover Delay"))
                        } minimumValueLabel: {
                            Text(L10n.text("Fast"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } maximumValueLabel: {
                            Text(L10n.text("Slow"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(L10n.text("Subfolder Tip")) {
                Toggle(L10n.text("Show a drop-down arrow beside hovered folders"), isOn: $settings.subfolderTipEnabled)
                Text(L10n.text("Click the arrow to browse everything inside a folder, to any depth, without leaving the current folder. Click an item to open it, ⌘-click to open a folder in a new tab, or ⌥-click to copy it."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var privacyTab: some View {
        Form {
            Section(L10n.text("Full Disk Access")) {
                FullDiskAccessControls()
            }

            Section(L10n.text("Analytics & Crash Reporting")) {
                Toggle(L10n.text("Share anonymous usage statistics"), isOn: $settings.isAnalyticsEnabled)
                    .onChange(of: settings.isAnalyticsEnabled) { _, newValue in
                        TelemetryService.shared.setAnalyticsEnabled(newValue)
                    }
                Text(L10n.text("Helps us improve Shark by sharing anonymous feature usage data. File names, folder paths, and terminal commands are never collected."))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Toggle(L10n.text("Send crash reports"), isOn: $settings.isCrashReportingEnabled)
                    .onChange(of: settings.isCrashReportingEnabled) { _, newValue in
                        TelemetryService.shared.setCrashReportingEnabled(newValue)
                    }
                Text(L10n.text("Automatically sends crash diagnostics to Firebase Crashlytics to help us diagnose and fix issues."))
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
            Section(L10n.text("Folders")) {
                Toggle(L10n.text("Double-click empty space to go up one level"), isOn: $marginUp)
            }
            Section(L10n.text("Tabs")) {
                Toggle(L10n.text("Double-click a tab to pin or unpin it"), isOn: $tabPin)
                Toggle(L10n.text("Scroll over the tab strip to switch tabs"), isOn: $tabScroll)
            }
            Section(L10n.text("Mouse buttons")) {
                Toggle(L10n.text("Side buttons go back and forward (⌃ + side button switches tabs)"), isOn: $sideButtons)
            }
            Text(L10n.text("All mouse actions are listed in Help › Shark Help."))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .formStyle(.grouped)
    }
}
