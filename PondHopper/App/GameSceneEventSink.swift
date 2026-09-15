@MainActor
protocol GameSceneEventSink: AnyObject {
    func receive(_ event: GameEvent)
}
