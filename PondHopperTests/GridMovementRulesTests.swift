import Testing
@testable import FinHopper

struct GridMovementRulesTests {
    @Test
    func blocksArenaEdgesObstaclesAndRowsBelowVisibleFloor() {
        let obstacle = GridPosition(column: 2, row: 8)
        let rules = GridMovementRules(
            columnCount: 9,
            maximumRow: 20,
            obstacles: [obstacle]
        )

        #expect(!rules.canMove(to: GridPosition(column: -1, row: 8), minimumRow: 2))
        #expect(!rules.canMove(to: GridPosition(column: 9, row: 8), minimumRow: 2))
        #expect(!rules.canMove(to: obstacle, minimumRow: 2))
        #expect(!rules.canMove(to: GridPosition(column: 3, row: 1), minimumRow: 2))
        #expect(rules.canMove(to: GridPosition(column: 3, row: 2), minimumRow: 2))
        #expect(!rules.canMove(to: GridPosition(column: 3, row: 21), minimumRow: 2))
    }

    @Test
    func clampsNegativeFloorToRowZero() {
        let rules = GridMovementRules(columnCount: 9, maximumRow: 20, obstacles: [])

        #expect(rules.canMove(to: GridPosition(column: 3, row: 0), minimumRow: -5))
        #expect(!rules.canMove(to: GridPosition(column: 3, row: -1), minimumRow: -5))
    }

    @Test
    func rejectsEverythingWhenFloorExceedsMaximumRow() {
        let rules = GridMovementRules(columnCount: 9, maximumRow: 5, obstacles: [])

        #expect(!rules.canMove(to: GridPosition(column: 3, row: 5), minimumRow: 6))
    }
}
