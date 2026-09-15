nonisolated struct GameSettings: Equatable, Sendable {
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var showsDirectionalPad: Bool

    static let defaults = GameSettings(
        soundEnabled: true,
        hapticsEnabled: true,
        showsDirectionalPad: false
    )
}
