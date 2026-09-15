@testable import FinHopper

@MainActor
final class RecordingAudioPlayer: GameAudioPlaying {
    private(set) var preloadCallCount = 0
    private(set) var playedEffects: [GameSoundEffect] = []

    func preload() {
        preloadCallCount += 1
    }

    func play(_ effect: GameSoundEffect) {
        playedEffects.append(effect)
    }
}
