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

    @Test @MainActor func toolbarAllowsDisplayModeCustomizationAndSupportsBothModes() {
        let toolbar = NSToolbar(identifier: ToolbarConfiguration.identifier)
        if #available(macOS 15.0, *) {
            toolbar.allowsDisplayModeCustomization = true
            #expect(toolbar.allowsDisplayModeCustomization)
        }

        toolbar.displayMode = .iconOnly
        ToolbarDisplayState.shared.update(from: toolbar)
        #expect(toolbar.displayMode == .iconOnly)
        #expect(!ToolbarDisplayState.shared.showsLabels)

        toolbar.displayMode = .iconAndLabel
        ToolbarDisplayState.shared.update(from: toolbar)
        #expect(toolbar.displayMode == .iconAndLabel)
        #expect(ToolbarDisplayState.shared.showsLabels)
    }

    @Test @MainActor func configureItemSetsPaletteLabelAndLabel() {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("search"))
        ToolbarConfiguration.configureItem(item)
        #expect(item.paletteLabel == L10n.text("Search"))
        #expect(item.label == L10n.text("Search"))
    }
}
