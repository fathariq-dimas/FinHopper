@MainActor
final class GameFeedbackService: GameFeedbackPerforming {
    private let audioPlayer: any GameAudioPlaying
    private let hapticProvider: any GameHapticProviding

    init(
        audioPlayer: any GameAudioPlaying = AVAudioGameService(),
        hapticProvider: any GameHapticProviding = UIKitGameHapticService()
    ) {
        self.audioPlayer = audioPlayer
        self.hapticProvider = hapticProvider
    }

    func preload() {
        audioPlayer.preload()
        hapticProvider.prepare()
    }

    func perform(_ event: GameFeedbackEvent, settings: GameSettings) {
        if settings.soundEnabled, let effect = event.soundEffect {
            audioPlayer.play(effect)
        }

        if settings.hapticsEnabled, let haptic = event.hapticKind {
            hapticProvider.play(haptic)
        }
    }
}
