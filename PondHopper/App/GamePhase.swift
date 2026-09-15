nonisolated enum GamePhase: Equatable, Sendable {
    case tutorial
    case menu
    case countdown(Int)
    case playing
    case paused
    case gameOver(GameOverReason)
}
