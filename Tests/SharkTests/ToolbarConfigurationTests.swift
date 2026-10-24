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

    @Test @MainActor func knownItemsGetNativeLabelsForBothDisplayModes() {
        let item = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier("search"))
        ToolbarConfiguration.applyLabel(to: item)
        #expect(item.paletteLabel == L10n.text("Search"))
        #expect(item.label == L10n.text("Search"))
    }

    @Test @MainActor func systemItemsKeepTheirOwnLabels() {
        let item = NSToolbarItem(itemIdentifier: .flexibleSpace)
        let before = item.label
        ToolbarConfiguration.applyLabel(to: item)
        #expect(item.label == before)
    }
}
