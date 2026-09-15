import AVFoundation
import OSLog

/// Manages looping background music independently from one-shot sound effects.
/// BGM uses the `.ambient` audio session so it mixes with system sounds and
/// respects the mute switch, consistent with the rest of the game audio.
@MainActor
final class GameMusicService {
    private let bundle: Bundle
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "FinHopper",
        category: "GameMusic"
    )

    private var player: AVAudioPlayer?
    private var isEnabled = true

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// Call once at app start to load and buffer the track.
    func preload() {
        guard player == nil else { return }

        guard let url = bundle.url(forResource: "bgm", withExtension: "mp3", subdirectory: "Sounds")
                     ?? bundle.url(forResource: "bgm", withExtension: "mp3") else {
            logger.error("bgm.mp3 not found in bundle")
            return
        }

        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1   // loop indefinitely
            p.volume = 0.45
            p.prepareToPlay()
            player = p
        } catch {
            logger.error("Unable to load bgm.mp3: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Start (or resume) playback if sound is enabled.
    func play(soundEnabled: Bool) {
        isEnabled = soundEnabled
        guard soundEnabled else { return }
        preload()
        guard let player, !player.isPlaying else { return }
        player.play()
    }

    /// Pause without resetting position — call when game is paused/backgrounded.
    func pause() {
        player?.pause()
    }

    /// Resume from where it was paused, if sound is still enabled.
    func resume(soundEnabled: Bool) {
        isEnabled = soundEnabled
        guard soundEnabled, let player, !player.isPlaying else { return }
        player.play()
    }

    /// Stop and reset to the beginning.
    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    /// Update whether music is allowed (e.g. user toggles sound in settings).
    func setSoundEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            guard let player, !player.isPlaying else { return }
            player.play()
        } else {
            player?.pause()
        }
    }
}
