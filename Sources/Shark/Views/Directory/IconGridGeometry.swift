import CoreGraphics

/// Estimated cell frames for the icon grid, used to marquee-select cells that are not rendered yet.
///
/// The constants mirror the modifiers in `IconsGridView` (grid padding, `LazyVGrid` spacing and
/// adaptive column, `IconGridItemView` size). Row height assumes names that wrap to two lines, so an
/// unrendered row of one-line names can sit up to 14pt per row off. Rendered rows are decided by
/// their exact frames, so this only affects rows that are not on screen.
enum IconGridGeometry {
    static let gridPadding: CGFloat = 20
    static let columnSpacing: CGFloat = 20
    static let rowSpacing: CGFloat = 24

    static func frame(ofIndex index: Int, columns: Int, iconSize: CGFloat, containerWidth: CGFloat) -> CGRect {
        let cols = CGFloat(max(1, columns))
        let cellMin = max(iconSize + 28, 96)
        let avail = max(0, containerWidth - 2 * gridPadding)
        let share = (avail - (cols - 1) * columnSpacing) / cols
        let colWidth = max(cellMin, min(cellMin + 32, share))
        let block = cols * colWidth + (cols - 1) * columnSpacing
        let leading = gridPadding + max(0, (avail - block) / 2)

        let itemWidth = max(iconSize + 28, 104)
        let itemHeight = iconSize + 38
        let col = CGFloat(index % max(1, columns))
        let row = CGFloat(index / max(1, columns))
        return CGRect(
            x: leading + col * (colWidth + columnSpacing) + (colWidth - itemWidth) / 2,
            y: gridPadding + row * (itemHeight + rowSpacing),
            width: itemWidth,
            height: itemHeight)
    }

    /// Indices of the cells whose frames intersect `rect`, ascending.
    static func indices(
        intersecting rect: CGRect, itemCount: Int, columns: Int, iconSize: CGFloat, containerWidth: CGFloat
    ) -> [Int] {
        guard itemCount > 0, columns > 0 else { return [] }
        let stride = iconSize + 38 + rowSpacing
        let lastRow = CGFloat((itemCount - 1) / columns)
        // Clamp in CGFloat first: a huge or negative rect must not trap on Int conversion.
        let first = min(max(((rect.minY - gridPadding) / stride).rounded(.down), 0), lastRow)
        let last = min(max(((rect.maxY - gridPadding) / stride).rounded(.down), 0), lastRow)
        guard first <= last else { return [] }

        var result: [Int] = []
        for row in Int(first)...Int(last) {
            for col in 0..<columns {
                let idx = row * columns + col
                guard idx < itemCount else { break }
                if rect.intersects(frame(ofIndex: idx, columns: columns, iconSize: iconSize, containerWidth: containerWidth)) {
                    result.append(idx)
                }
            }
        }
        return result
    }
}
