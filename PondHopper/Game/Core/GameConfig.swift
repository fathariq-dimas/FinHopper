nonisolated struct GameConfig: Equatable, Sendable {
    let columns: Int
    let movementDuration: Double
    let maximumBreath: Double
    let countdownSeconds: Int
    let rowsPerDifficultyTier: Int
    let maximumDifficultyTier: Int

    static let live = GameConfig(
            columns: 7,
        movementDuration: 0.12,
        maximumBreath: 10,
        countdownSeconds: 3,
        rowsPerDifficultyTier: 20,
        maximumDifficultyTier: 6
    )

    func difficulty(for score: Int) -> DifficultyParameters {
        let safeScore = max(0, score)
        let tier = min(safeScore / rowsPerDifficultyTier, maximumDifficultyTier)
        let speedMultiplier = 1 + (Double(tier) * 0.10)
        let spawnMultiplier = max(0.60, 1 - (Double(tier) * 0.07))
        let pondGapIncrease = (tier * 3) / max(1, maximumDifficultyTier)

        return DifficultyParameters(
            tier: tier,
            carSpeedInScreenWidths: 0.55 * speedMultiplier,
            truckSpeedInScreenWidths: 0.42 * speedMultiplier,
            spawnInterval: 1.8 * spawnMultiplier,
            pondGapRows: 9 + pondGapIncrease,
            maximumRoadLanes: min(5, 2 + (tier / 2))
        )
    }

    func replacingMaximumBreath(with override: Double?) -> GameConfig {
        guard let override, override > 0 else { return self }

        return GameConfig(
            columns: columns,
            movementDuration: movementDuration,
            maximumBreath: override,
            countdownSeconds: countdownSeconds,
            rowsPerDifficultyTier: rowsPerDifficultyTier,
            maximumDifficultyTier: maximumDifficultyTier
        )
    }
}
