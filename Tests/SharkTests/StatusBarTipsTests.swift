import Foundation
import Testing
@testable import Shark

@MainActor
struct StatusBarTipsTests {
    @Test func onlyOneOfTenRollsShowsATip() {
        let results = (0..<10).compactMap { StatusBarTips.choose(roll: $0, index: 0) }
        #expect(results == [StatusBarTips.tips[0]])
        #expect(StatusBarTips.choose(roll: 0, index: -1) == nil)
    }

    @Test func selectionAndOperationsDismissTips() {
        let state = NavigationState(initialURL: URL(fileURLWithPath: "/tmp"))
        state.statusBarTip = StatusBarTips.tips[0]
        state.selectedItemIDs = [URL(fileURLWithPath: "/tmp/file")]
        #expect(state.statusBarTip == nil)
        state.selectedItemIDs = []
        #expect(state.statusBarTip == nil)
        state.statusBarTip = StatusBarTips.tips[1]
        state.activeOperationTitle = "Copying"
        #expect(state.statusBarTip == nil)
        state.activeOperationTitle = nil
        #expect(state.statusBarTip == nil)
    }
}
