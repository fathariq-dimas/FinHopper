nonisolated struct GameSnapshot: Equatable, Sendable {
    var score: Int
    var bestScore: Int
    var breathRemaining: Double
    var targetDirection: MoveDirection?
    var seed: UInt64?

    static func initial(bestScore: Int, config: GameConfig) -> GameSnapshot {
        GameSnapshot(
            score: 0,
            bestScore: bestScore,
            breathRemaining: config.maximumBreath,
            targetDirection: nil,
            seed: nil
        )
    }
}
