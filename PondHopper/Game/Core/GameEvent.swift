nonisolated enum GameEvent: Equatable, Sendable {
    case movementCompleted(GridPosition)
    case movementBlocked
    case tutorialWrongInput
    case pondAbsorbed
    case scoreChanged(Int)
    case breathChanged(Double)
    case targetDirectionChanged(MoveDirection?)
    case feedback(GameFeedbackEvent)
    case gameOver(GameOverReason)
}
