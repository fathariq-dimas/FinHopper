nonisolated struct GridPosition: Equatable, Hashable, Sendable {
    let column: Int
    let row: Int

    func moved(_ direction: MoveDirection) -> GridPosition {
        switch direction {
        case .up:
            GridPosition(column: column, row: row + 1)
        case .down:
            GridPosition(column: column, row: row - 1)
        case .left:
            GridPosition(column: column - 1, row: row)
        case .right:
            GridPosition(column: column + 1, row: row)
        }
    }
}
