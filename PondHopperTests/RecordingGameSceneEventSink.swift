@testable import FinHopper

@MainActor
final class RecordingGameSceneEventSink: GameSceneEventSink {
    private(set) var events: [GameEvent] = []

    func receive(_ event: GameEvent) {
        events.append(event)
    }

    func reset() {
        events.removeAll()
    }
}
