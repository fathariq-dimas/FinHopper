import Foundation

nonisolated struct RoadLaneDefinition: Equatable, Sendable {
    let row: Int
    let direction: VehicleTravelDirection
    let vehicleKind: VehicleKind
    let speedInScreenWidths: Double
    let spawnInterval: Double
    let phaseOffset: Double

    func spawnTime(for index: Int) -> Double {
        phaseOffset + (Double(index) * spawnInterval)
    }

    func centerColumn(
        forSpawnIndex index: Int,
        at time: Double,
        columnCount: Int
    ) -> Double {
        let speedInColumns = speedInScreenWidths * Double(columnCount)
        let elapsed = time - spawnTime(for: index)
        let leadingMargin = vehicleKind.lengthInColumns / 2

        switch direction {
        case .right:
            return -leadingMargin + (speedInColumns * elapsed)
        case .left:
            return Double(columnCount) + leadingMargin - (speedInColumns * elapsed)
        }
    }

    func activeSpawnIndices(at time: Double, columnCount: Int) -> ClosedRange<Int> {
        let speedInColumns = max(0.001, speedInScreenWidths * Double(columnCount))
        let travelDistance = Double(columnCount) + vehicleKind.lengthInColumns
        let travelDuration = travelDistance / speedInColumns
        let first = Int(floor((time - phaseOffset - travelDuration) / spawnInterval)) - 1
        let last = Int(floor((time - phaseOffset) / spawnInterval)) + 1
        return first...last
    }

    func isOccupied(column: Double, at time: Double, columnCount: Int) -> Bool {
        let playerHalfWidth = CollisionGeometry.playerWidthInColumns / 2
        let collisionDistance = (vehicleKind.lengthInColumns / 2) + playerHalfWidth

        return activeSpawnIndices(at: time, columnCount: columnCount).contains { index in
            let center = centerColumn(
                forSpawnIndex: index,
                at: time,
                columnCount: columnCount
            )
            return abs(center - column) <= collisionDistance
        }
    }
}
