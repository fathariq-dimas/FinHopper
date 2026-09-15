import Testing
@testable import FinHopper

struct GameConfigTests {
    @Test
    func difficultyIsBounded() {
        let initial = GameConfig.live.difficulty(for: 0)
        let maximum = GameConfig.live.difficulty(for: 10_000)

        #expect(GameConfig.live.columns == 7)
        #expect(initial.tier == 0)
        #expect(initial.pondGapRows == 9)
        #expect(initial.maximumRoadLanes == 2)
        #expect(maximum.tier == 6)
        #expect(maximum.pondGapRows == 12)
        #expect(maximum.maximumRoadLanes == 5)
        #expect(maximum.spawnInterval >= 1.8 * 0.60)
    }

    @Test
    func pondGapGrowsMonotonicallyAcrossDifficultyTiers() {
        let gaps = (0...GameConfig.live.maximumDifficultyTier).map { tier in
            GameConfig.live.difficulty(for: tier * GameConfig.live.rowsPerDifficultyTier).pondGapRows
        }

        #expect(gaps == [9, 9, 10, 10, 11, 11, 12])
    }

    @Test
    func gridMovementUsesOneTile() {
        let origin = GridPosition(column: 3, row: 4)

        #expect(origin.moved(.up) == GridPosition(column: 3, row: 5))
        #expect(origin.moved(.down) == GridPosition(column: 3, row: 3))
        #expect(origin.moved(.left) == GridPosition(column: 2, row: 4))
        #expect(origin.moved(.right) == GridPosition(column: 4, row: 4))
    }
}
