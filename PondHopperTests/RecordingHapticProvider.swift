@testable import FinHopper

@MainActor
final class RecordingHapticProvider: GameHapticProviding {
    private(set) var prepareCallCount = 0
    private(set) var playedKinds: [GameHapticKind] = []

    func prepare() {
        prepareCallCount += 1
    }

    func play(_ kind: GameHapticKind) {
        playedKinds.append(kind)
    }
}
