nonisolated struct DifficultyParameters: Equatable, Sendable {
    let tier: Int
    let carSpeedInScreenWidths: Double
    let truckSpeedInScreenWidths: Double
    let spawnInterval: Double
    let pondGapRows: Int
    let maximumRoadLanes: Int
}
