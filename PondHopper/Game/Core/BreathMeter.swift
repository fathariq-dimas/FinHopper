nonisolated struct BreathMeter: Equatable, Sendable {
    let maximum: Double

    private(set) var remaining: Double
    private(set) var visitedPondIDs: Set<Int> = []

    init(maximum: Double) {
        let safeMaximum = max(0, maximum)
        self.maximum = safeMaximum
        remaining = safeMaximum
    }

    @discardableResult
    mutating func visitPond(id: Int, adding seconds: Double = 5) -> Bool {
        let insertion = visitedPondIDs.insert(id)
        guard insertion.inserted else { return false }

        remaining = min(maximum, remaining + max(0, seconds))
        return true
    }

    @discardableResult
    mutating func advance(by deltaTime: Double, isSafe: Bool) -> Bool {
        guard deltaTime > 0, !isSafe, remaining > 0 else { return false }

        remaining = max(0, remaining - deltaTime)
        return remaining == 0
    }
}
