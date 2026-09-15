import Testing
@testable import FinHopper

@MainActor
struct GameFeedbackServiceTests {
    @Test
    func preloadWarmsAudioAndHaptics() {
        let audio = RecordingAudioPlayer()
        let haptics = RecordingHapticProvider()
        let service = GameFeedbackService(audioPlayer: audio, hapticProvider: haptics)

        service.preload()

        #expect(audio.preloadCallCount == 1)
        #expect(haptics.prepareCallCount == 1)
    }

    @Test
    func enabledFeedbackMapsToMatchingSoundAndHaptic() {
        let audio = RecordingAudioPlayer()
        let haptics = RecordingHapticProvider()
        let service = GameFeedbackService(audioPlayer: audio, hapticProvider: haptics)

        service.perform(.splash, settings: .defaults)
        service.perform(.criticalBreath, settings: .defaults)
        service.perform(.vehicleCollision, settings: .defaults)
        service.perform(.countdown, settings: .defaults)

        #expect(audio.playedEffects == [.splash, .warning, .collision, .countdown])
        #expect(haptics.playedKinds == [.success, .warning, .error, .lightImpact])
    }

    @Test
    func settingsGateEachFeedbackChannelIndependently() {
        let audio = RecordingAudioPlayer()
        let haptics = RecordingHapticProvider()
        let service = GameFeedbackService(audioPlayer: audio, hapticProvider: haptics)

        service.perform(
            .hop,
            settings: GameSettings(
                soundEnabled: false,
                hapticsEnabled: true,
                showsDirectionalPad: false
            )
        )
        service.perform(
            .vehicleCollision,
            settings: GameSettings(
                soundEnabled: true,
                hapticsEnabled: false,
                showsDirectionalPad: false
            )
        )

        #expect(audio.playedEffects == [.collision])
        #expect(haptics.playedKinds == [.lightImpact])
    }

    @Test
    func passingVehicleIsSoundOnlyAndRespectsMute() {
        let audio = RecordingAudioPlayer()
        let haptics = RecordingHapticProvider()
        let service = GameFeedbackService(audioPlayer: audio, hapticProvider: haptics)
        service.perform(.vehiclePass, settings: .defaults)
        #expect(audio.playedEffects == [.vehiclePass])
        #expect(haptics.playedKinds.isEmpty)

        var muted = GameSettings.defaults
        muted.soundEnabled = false
        service.perform(.vehiclePass, settings: muted)
        #expect(audio.playedEffects == [.vehiclePass])
        #expect(haptics.playedKinds.isEmpty)
    }

    @Test
    func blockedMovementIsHapticOnly() {
        let audio = RecordingAudioPlayer()
        let haptics = RecordingHapticProvider()
        let service = GameFeedbackService(audioPlayer: audio, hapticProvider: haptics)

        service.perform(.blockedMove, settings: .defaults)

        #expect(audio.playedEffects.isEmpty)
        #expect(haptics.playedKinds == [.blockedImpact])
    }
}
