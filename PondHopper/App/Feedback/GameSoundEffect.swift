nonisolated enum GameSoundEffect: String, CaseIterable, Hashable, Sendable {
    case hop
    case splash
    case warning
    case collision
    case vehiclePass
    case countdown

    var volume: Float {
        switch self {
        case .hop: 0.30
        case .splash: 1.00
        case .collision: 0.95
        case .vehiclePass: 0.40
        case .warning, .countdown: 1
        }
    }
}
