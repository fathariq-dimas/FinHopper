nonisolated struct ScoreTracker: Equatable, Sendable {
    private(set) var highestRow = 0

    @discardableResult
    mutating func record(row: Int) -> Bool {
        guard row > highestRow else { return false }

        highestRow = row
        return true
    }
}
