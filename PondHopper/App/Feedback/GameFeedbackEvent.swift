nonisolated enum GameFeedbackEvent: Equatable, Sendable {
    case hop
    case splash
    case criticalBreath
    case blockedMove
    case vehicleCollision
    case vehiclePass
    case countdown

    var soundEffect: GameSoundEffect? {
        switch self {
        case .hop:
            .hop
        case .splash:
            .splash
        case .criticalBreath:
            .warning
        case .vehicleCollision:
            .collision
        case .vehiclePass:
            .vehiclePass
        case .countdown:
            .countdown
        case .blockedMove:
            nil
        }
    }

    var hapticKind: GameHapticKind? {
        switch self {
        case .hop, .countdown:
            .lightImpact
        case .blockedMove:
            .blockedImpact
        case .splash:
            .success
        case .criticalBreath:
            .warning
        case .vehicleCollision:
            .error
        case .vehiclePass:
            nil
        }
    }
}
