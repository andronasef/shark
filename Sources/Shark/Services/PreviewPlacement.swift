import Foundation

enum PreviewPlacement {
    static func frame(anchor: CGPoint, desiredSize: CGSize, visibleFrame bounds: CGRect) -> CGRect {
        let width = min(max(1, desiredSize.width), max(1, bounds.width))
        let height = min(max(1, desiredSize.height), max(1, bounds.height))
        let gap: CGFloat = 16
        var x = anchor.x + gap
        if x + width > bounds.maxX { x = anchor.x - gap - width }
        var y = anchor.y - gap - height
        if y < bounds.minY { y = anchor.y + gap }
        return CGRect(x: min(max(bounds.minX, x), bounds.maxX - width),
                      y: min(max(bounds.minY, y), bounds.maxY - height), width: width, height: height)
    }
}
