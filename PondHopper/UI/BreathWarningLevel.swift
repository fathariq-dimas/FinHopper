nonisolated enum BreathWarningLevel: Int, Equatable, Sendable {
    case none
    case caution
    case danger

    static func resolve(
        remaining: Double,
        maximum: Double,
        isActive: Bool
    ) -> BreathWarningLevel {
        guard isActive, maximum > 0 else { return .none }

        let fraction = max(0, remaining) / maximum
        if fraction <= 0.20 {
            return .danger
        }
        if fraction <= 0.40 {
            return .caution
        }
        return .none
    }
}
