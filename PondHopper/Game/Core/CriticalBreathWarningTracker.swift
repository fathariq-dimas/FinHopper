nonisolated struct CriticalBreathWarningTracker: Equatable, Sendable {
    private let threshold: Double
    private var didWarn = false

    init(maximumBreath: Double) {
        threshold = min(3, max(0, maximumBreath) * 0.3)
    }

    mutating func shouldWarn(for remainingBreath: Double) -> Bool {
        guard !didWarn, remainingBreath > 0, remainingBreath <= threshold else { return false }

        didWarn = true
        return true
    }

    mutating func reset() {
        didWarn = false
    }
}
