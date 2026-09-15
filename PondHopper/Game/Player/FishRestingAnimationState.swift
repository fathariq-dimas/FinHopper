nonisolated enum FishRestingAnimationState: Equatable, Hashable, Sendable {
    case landIdle
    case cautionBreath
    case dangerBreath
    case pondRecovery

    static let cautionBreathFraction = 0.40
    static let dangerBreathFraction = 0.20

    static func resolve(
        remainingBreath: Double,
        maximumBreath: Double,
        isOnActivePond: Bool
    ) -> FishRestingAnimationState {
        if isOnActivePond {
            return .pondRecovery
        }

        guard maximumBreath > 0 else { return .landIdle }

        if remainingBreath <= maximumBreath * dangerBreathFraction {
            return .dangerBreath
        }
        if remainingBreath <= maximumBreath * cautionBreathFraction {
            return .cautionBreath
        }
        return .landIdle
    }
}
