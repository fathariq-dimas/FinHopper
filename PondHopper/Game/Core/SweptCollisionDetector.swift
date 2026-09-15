import CoreGraphics

nonisolated enum SweptCollisionDetector {
    static func intersects(
        firstFrom firstStart: CGPoint,
        firstTo firstEnd: CGPoint,
        firstSize: CGSize,
        secondFrom secondStart: CGPoint,
        secondTo secondEnd: CGPoint,
        secondSize: CGSize
    ) -> Bool {
        let relativeStartX = Double(firstStart.x - secondStart.x)
        let relativeStartY = Double(firstStart.y - secondStart.y)
        let relativeDeltaX = Double((firstEnd.x - firstStart.x) - (secondEnd.x - secondStart.x))
        let relativeDeltaY = Double((firstEnd.y - firstStart.y) - (secondEnd.y - secondStart.y))
        let combinedHalfWidth = Double(firstSize.width + secondSize.width) / 2
        let combinedHalfHeight = Double(firstSize.height + secondSize.height) / 2

        var entryTime = 0.0
        var exitTime = 1.0

        guard clipAxis(
            start: relativeStartX,
            delta: relativeDeltaX,
            halfExtent: combinedHalfWidth,
            entryTime: &entryTime,
            exitTime: &exitTime
        ) else { return false }

        return clipAxis(
            start: relativeStartY,
            delta: relativeDeltaY,
            halfExtent: combinedHalfHeight,
            entryTime: &entryTime,
            exitTime: &exitTime
        )
    }

    private static func clipAxis(
        start: Double,
        delta: Double,
        halfExtent: Double,
        entryTime: inout Double,
        exitTime: inout Double
    ) -> Bool {
        guard abs(delta) > 0.000_001 else {
            return abs(start) <= halfExtent
        }

        let firstIntersection = (-halfExtent - start) / delta
        let secondIntersection = (halfExtent - start) / delta
        entryTime = max(entryTime, min(firstIntersection, secondIntersection))
        exitTime = min(exitTime, max(firstIntersection, secondIntersection))
        return entryTime <= exitTime
    }
}
