import XCTest
@testable import Shark

final class MouseBindingsTests: XCTestCase {
    func testTrackpadTravelMapsToWholeTabSteps() {
        var accumulator = ScrollStepAccumulator()
        XCTAssertEqual(accumulator.add(delta: -20, precise: true), 0)   // not enough yet
        XCTAssertEqual(accumulator.add(delta: -20, precise: true), 1)   // 40 pt total: one step, 10 carried
        XCTAssertEqual(accumulator.add(delta: 45, precise: true), -1)   // reverse direction
    }

    func testOneWheelNotchIsOneTab() {
        var accumulator = ScrollStepAccumulator()
        XCTAssertEqual(accumulator.add(delta: -1, precise: false), 1)
        XCTAssertEqual(accumulator.add(delta: 1, precise: false), -1)
        XCTAssertEqual(accumulator.add(delta: -3, precise: false), 3)
    }

    func testResetDropsPartialTravel() {
        var accumulator = ScrollStepAccumulator()
        _ = accumulator.add(delta: -25, precise: true)
        accumulator.reset()
        XCTAssertEqual(accumulator.add(delta: -10, precise: true), 0)
    }

    func testMouseActionsDefaultToOnAndCanBeSwitchedOff() {
        let setting = MouseSetting.sideButtons
        UserDefaults.standard.removeObject(forKey: setting.key)
        XCTAssertTrue(setting.isEnabled)
        UserDefaults.standard.set(false, forKey: setting.key)
        XCTAssertFalse(setting.isEnabled)
        UserDefaults.standard.removeObject(forKey: setting.key)
    }

    func testHelpDocumentsEveryZoneAndEachNewBinding() {
        let text = MouseHelp.zones.flatMap { zone in zone.bindings.map { "\(zone.title) \($0.gesture) \($0.action)" } }.joined(separator: "\n")
        for expected in ["Go up one level", "Pin or unpin", "Mouse side button (back)", "Cycle through tabs"] {
            XCTAssertTrue(text.contains(expected), expected)
        }
        XCTAssertEqual(Set(MouseHelp.zones.map(\.id)).count, MouseHelp.zones.count)
        XCTAssertTrue(MouseHelp.zones.allSatisfy { !$0.bindings.isEmpty })
    }
}
