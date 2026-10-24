import Foundation
import AppKit
import Testing
@testable import Shark

struct ToolbarConfigurationTests {
    @Test func removedItemsGiveLocationMoreSpace() {
        #expect(ToolbarConfiguration.locationWidth(availableWidth: 900, otherItemWidths: [100, 200]) > ToolbarConfiguration.locationWidth(availableWidth: 900, otherItemWidths: [100, 200, 100]))
    }

    @Test func narrowWindowsKeepMinimumPathWidth() {
        #expect(ToolbarConfiguration.locationWidth(availableWidth: 300, otherItemWidths: [400]) == 100)
    }

    @Test func restorePreservesOrderingAndRemovalWhileDroppingObsoleteAndDuplicateIDs() {
        #expect(ToolbarConfiguration.validatedIdentifiers(["search", "tags", "search", "view-mode"], allowed: ["search", "view-mode"]) == ["search", "view-mode"])
        #expect(ToolbarConfiguration.validatedIdentifiers([], allowed: ["search"]).isEmpty)
    }

    @Test @MainActor func toolbarForcesIconOnlyDisplayMode() {
        let toolbar = NSToolbar(identifier: ToolbarConfiguration.identifier)
        toolbar.displayMode = .iconAndLabel
        if #available(macOS 15.0, *) {
            toolbar.allowsDisplayModeCustomization = false
            #expect(!toolbar.allowsDisplayModeCustomization)
        }
        toolbar.displayMode = .iconOnly
        #expect(toolbar.displayMode == .iconOnly)
    }
}
