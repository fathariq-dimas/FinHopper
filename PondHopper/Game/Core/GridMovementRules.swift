nonisolated struct GridMovementRules: Equatable, Sendable {
    let columnCount: Int
    let maximumRow: Int
    let obstacles: Set<GridPosition>

    /// Validates a candidate destination against the arena bounds, the static
    /// obstacle set, and a caller-provided lower row bound.
    ///
    /// `minimumRow` is the lowest row the player is allowed to reach. The scene
    /// derives it from the camera geometry so the floor matches the rows that
    /// are actually fully visible on screen: a tile that is only half visible
    /// at the bottom edge must not be reachable.
    func canMove(
        to position: GridPosition,
        minimumRow: Int
    ) -> Bool {
        let lowerBound = max(0, minimumRow)

        guard lowerBound <= maximumRow else { return false }

        return (0..<columnCount).contains(position.column)
            && (lowerBound...maximumRow).contains(position.row)
            && !obstacles.contains(position)
    }
}
