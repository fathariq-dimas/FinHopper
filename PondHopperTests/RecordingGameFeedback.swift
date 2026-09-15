@testable import FinHopper

@MainActor
final class RecordingGameFeedback: GameFeedbackPerforming {
    private(set) var preloadCallCount = 0
    private(set) var events: [GameFeedbackEvent] = []
    private(set) var receivedSettings: [GameSettings] = []

    func preload() {
        preloadCallCount += 1
    }

    func perform(_ event: GameFeedbackEvent, settings: GameSettings) {
        events.append(event)
        receivedSettings.append(settings)
    }
}
