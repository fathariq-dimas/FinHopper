@MainActor
protocol GameFeedbackPerforming: AnyObject {
    func preload()
    func perform(_ event: GameFeedbackEvent, settings: GameSettings)
}
