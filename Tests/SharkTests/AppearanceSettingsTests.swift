import XCTest
import SwiftUI
import AppKit
@testable import Shark

@MainActor
final class AppearanceSettingsTests: XCTestCase {
    func testAppearanceCasesAndValues() {
        XCTAssertEqual(AppAppearance.allCases.count, 3)
        XCTAssertEqual(AppAppearance.system.rawValue, "System Default")
        XCTAssertEqual(AppAppearance.light.rawValue, "Light")
        XCTAssertEqual(AppAppearance.dark.rawValue, "Dark")
        XCTAssertEqual(AppAppearance.system.id, "System Default")
    }

    func testAppearanceMappings() {
        XCTAssertNil(AppAppearance.system.nsAppearance)
        XCTAssertNil(AppAppearance.system.colorScheme)

        XCTAssertEqual(AppAppearance.light.nsAppearance?.name, NSAppearance.Name.aqua)
        XCTAssertEqual(AppAppearance.light.colorScheme, .light)

        XCTAssertEqual(AppAppearance.dark.nsAppearance?.name, NSAppearance.Name.darkAqua)
        XCTAssertEqual(AppAppearance.dark.colorScheme, .dark)
    }

    func testUnknownRawValueFallsBackToSystem() {
        XCTAssertNil(AppAppearance(rawValue: "InvalidValue"))
        let original = SharkSettings.shared.appAppearance
        defer {
            SharkSettings.shared.appAppearance = original
            SharkSettings.shared.applyAppearance()
        }

        SharkSettings.shared.appAppearance = "invalid"
        XCTAssertEqual(SharkSettings.shared.selectedAppearance, .system)
    }

    func testAppearanceSelectionAndApplication() {
        let original = SharkSettings.shared.appAppearance
        defer {
            SharkSettings.shared.appAppearance = original
            SharkSettings.shared.applyAppearance()
        }

        SharkSettings.shared.appAppearance = AppAppearance.light.rawValue
        XCTAssertEqual(SharkSettings.shared.selectedAppearance, .light)
        SharkSettings.shared.applyAppearance()
        if let app = NSApp {
            XCTAssertEqual(app.appearance?.name, NSAppearance.Name.aqua)
        }

        SharkSettings.shared.appAppearance = AppAppearance.dark.rawValue
        XCTAssertEqual(SharkSettings.shared.selectedAppearance, .dark)
        SharkSettings.shared.applyAppearance()
        if let app = NSApp {
            XCTAssertEqual(app.appearance?.name, NSAppearance.Name.darkAqua)
        }

        SharkSettings.shared.appAppearance = AppAppearance.system.rawValue
        XCTAssertEqual(SharkSettings.shared.selectedAppearance, .system)
        SharkSettings.shared.applyAppearance()
        if let app = NSApp {
            XCTAssertNil(app.appearance)
        }
    }
}
