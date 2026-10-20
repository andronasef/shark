import Foundation
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

@MainActor
public final class TelemetryService: ObservableObject {
    public static let shared = TelemetryService()

    private(set) public var isConfigured = false

    private init() {}

    public func initialize() {
        guard !isConfigured else { return }

        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: plistPath) else {
            return
        }

        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
        isConfigured = true

        let settings = SharkSettings.shared
        setAnalyticsEnabled(settings.isAnalyticsEnabled)
        setCrashReportingEnabled(settings.isCrashReportingEnabled)

        if settings.isAnalyticsEnabled {
            logEvent("app_launch", parameters: [
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            ])
        }
    }

    public func setAnalyticsEnabled(_ enabled: Bool) {
        guard isConfigured else { return }
        Analytics.setAnalyticsCollectionEnabled(enabled)
    }

    public func setCrashReportingEnabled(_ enabled: Bool) {
        guard isConfigured else { return }
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }

    /// Logs an analytics event if analytics collection is enabled.
    /// Strictly privacy-preserving: no filenames, paths, or terminal commands allowed.
    public func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isConfigured, SharkSettings.shared.isAnalyticsEnabled else { return }
        Analytics.logEvent(name, parameters: parameters)
    }

    /// Records a non-fatal error to Crashlytics if crash reporting is enabled.
    public func recordError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        guard isConfigured, SharkSettings.shared.isCrashReportingEnabled else { return }
        if let info = additionalInfo {
            for (key, val) in info {
                Crashlytics.crashlytics().setCustomValue(val, forKey: key)
            }
        }
        Crashlytics.crashlytics().record(error: error)
    }

    /// Sets diagnostic context keys in Crashlytics (e.g. view mode, tab count)
    public func setDiagnosticContext(key: String, value: Any) {
        guard isConfigured, SharkSettings.shared.isCrashReportingEnabled else { return }
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    // MARK: - Safe Event Logging Conveniences

    public func logTabOpened(totalTabs: Int) {
        logEvent("tab_opened", parameters: ["tab_count": totalTabs])
        setDiagnosticContext(key: "tab_count", value: totalTabs)
    }

    public func logTabClosed(totalTabs: Int) {
        logEvent("tab_closed", parameters: ["tab_count": totalTabs])
        setDiagnosticContext(key: "tab_count", value: totalTabs)
    }

    public func logSplitViewToggled(isSplit: Bool) {
        logEvent("split_view_toggled", parameters: ["is_split": isSplit])
        setDiagnosticContext(key: "is_split", value: isSplit)
    }

    public func logTerminalToggled(isVisible: Bool) {
        logEvent("terminal_toggled", parameters: ["is_visible": isVisible])
        setDiagnosticContext(key: "terminal_visible", value: isVisible)
    }

    public func logViewModeChanged(mode: String) {
        logEvent("view_mode_changed", parameters: ["mode": mode])
        setDiagnosticContext(key: "view_mode", value: mode)
    }
}
