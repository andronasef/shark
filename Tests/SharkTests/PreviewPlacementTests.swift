import Foundation
import Testing
@testable import Shark

struct PreviewPlacementTests {
    @Test func oversizedPreviewFitsNegativeOriginDisplay() {
        let bounds = CGRect(x: -1280, y: -200, width: 1280, height: 720)
        for anchor in [CGPoint(x: -1280, y: -200), CGPoint(x: -1, y: 519)] {
            let result = PreviewPlacement.frame(anchor: anchor, desiredSize: CGSize(width: 2000, height: 1500), visibleFrame: bounds)
            #expect(bounds.contains(result))
            #expect(result.width > 0 && result.height > 0)
        }
    }

    @Test func bottomEdgePlacesWholePreviewAbovePointer() {
        let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let result = PreviewPlacement.frame(anchor: CGPoint(x: 700, y: 10), desiredSize: CGSize(width: 480, height: 400), visibleFrame: bounds)
        #expect(result.minY > 10)
        #expect(bounds.contains(result))
    }
}
