import XCTest
import SwiftUI
@testable import Shark

@MainActor
final class TelemetryServiceTests: XCTestCase {

    func testTelemetryServiceInitializationDoesNotCrash() {
        let telemetry = TelemetryService.shared
        // In unit test environment, Bundle.main may not contain GoogleService-Info.plist.
        // It must safely handle missing config without throwing or crashing.
        telemetry.initialize()
        // Calling initialize twice should be a safe no-op
        telemetry.initialize()
    }

    func testTelemetryServiceToggles() {
        let telemetry = TelemetryService.shared
        telemetry.setAnalyticsEnabled(true)
        telemetry.setAnalyticsEnabled(false)
        telemetry.setCrashReportingEnabled(true)
        telemetry.setCrashReportingEnabled(false)
    }

    func testTelemetrySafeEventLogging() {
        let telemetry = TelemetryService.shared
        // Safe events should log without error
        telemetry.logEvent("view_mode_changed", parameters: ["mode": "details"])
        telemetry.logEvent("tab_opened", parameters: ["tab_count": 2])
        telemetry.logEvent("split_view_toggled", parameters: ["is_split": true])
        telemetry.setDiagnosticContext(key: "active_view_mode", value: "details")
    }

    func testPrivacySettingsDefaults() {
        let settings = SharkSettings.shared
        XCTAssertTrue(settings.isAnalyticsEnabled, "Analytics should be enabled by default")
        XCTAssertTrue(settings.isCrashReportingEnabled, "Crashlytics should be enabled by default")
    }
}
