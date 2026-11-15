import Foundation
import Testing
@testable import Shark

struct IconGridGeometryTests {
    private func hits(
        _ rect: CGRect, itemCount: Int = 20, columns: Int = 6, iconSize: CGFloat = 64, width: CGFloat = 800
    ) -> [Int] {
        IconGridGeometry.indices(
            intersecting: rect, itemCount: itemCount, columns: columns, iconSize: iconSize, containerWidth: width)
    }

    @Test func gapsSelectNothing() {
        #expect(hits(CGRect(x: 130, y: 40, width: 20, height: 60)).isEmpty)
        #expect(hits(CGRect(x: 30, y: 124, width: 60, height: 20)).isEmpty)
    }

    @Test func selectsOnlyTouchedCells() {
        #expect(hits(CGRect(x: 40, y: 40, width: 30, height: 30)) == [0])
        #expect(hits(CGRect(x: 100, y: 40, width: 70, height: 60)) == [0, 1])
        #expect(hits(CGRect(x: 100, y: 100, width: 70, height: 60)) == [0, 1, 6, 7])
    }

    @Test func nothingBeyondTheItems() {
        #expect(hits(CGRect(x: 420, y: 150, width: 20, height: 20), itemCount: 8).isEmpty)
        #expect(hits(CGRect(x: 40, y: 1000, width: 30, height: 30)).isEmpty)
        #expect(hits(CGRect(x: 0, y: 0, width: 10, height: 10)).isEmpty)
        #expect(hits(CGRect(x: 0, y: 150, width: 800, height: 20), itemCount: 8) == [6, 7])
        #expect(hits(CGRect(x: 0, y: 0, width: 800, height: 800), itemCount: 0).isEmpty)
        #expect(hits(CGRect(x: -1e12, y: -1e12, width: 2e12, height: 2e12), itemCount: 8).count == 8)
    }

    @Test func columnWidthIsCapped() {
        #expect(hits(CGRect(x: 143, y: 40, width: 4, height: 40), itemCount: 10, columns: 2, width: 340) == [0])
        #expect(hits(CGRect(x: 297, y: 40, width: 3, height: 40), itemCount: 10, columns: 2, width: 340).isEmpty)
    }

    @Test func largeIcons() {
        #expect(hits(CGRect(x: 177, y: 30, width: 18, height: 30), itemCount: 10, columns: 5, iconSize: 128, width: 900).isEmpty)
        #expect(hits(CGRect(x: 170, y: 30, width: 30, height: 30), itemCount: 10, columns: 5, iconSize: 128, width: 900) == [0, 1])
    }
}
