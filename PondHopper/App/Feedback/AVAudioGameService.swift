import AVFoundation
import OSLog

@MainActor
final class AVAudioGameService: GameAudioPlaying {
    private let bundle: Bundle
    private let audioSession: AVAudioSession
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "FinHopper",
        category: "GameAudio"
    )

    private var players: [GameSoundEffect: AVAudioPlayer] = [:]
    private var didAttemptPreload = false

    init(
        bundle: Bundle = .main,
        audioSession: AVAudioSession = .sharedInstance()
    ) {
        self.bundle = bundle
        self.audioSession = audioSession
    }

    func preload() {
        guard !didAttemptPreload else { return }
        didAttemptPreload = true

        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            logger.error("Unable to configure the ambient audio session: \(error.localizedDescription, privacy: .public)")
        }

        for effect in GameSoundEffect.allCases {
            guard let url = soundURL(for: effect) else {
                logger.error("Missing bundled sound: \(effect.rawValue, privacy: .public).wav")
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = effect.volume
                player.prepareToPlay()
                players[effect] = player
            } catch {
                logger.error(
                    "Unable to preload \(effect.rawValue, privacy: .public).wav: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    func play(_ effect: GameSoundEffect) {
        preload()
        guard let player = players[effect] else { return }

        if effect == .vehiclePass, player.isPlaying { return }
        if effect == .collision {
            players[.vehiclePass]?.stop()
            players[.hop]?.stop()
        }

        player.currentTime = 0
        player.play()
    }

    private func soundURL(for effect: GameSoundEffect) -> URL? {
        bundle.url(
            forResource: effect.rawValue,
            withExtension: "wav",
            subdirectory: "Sounds"
        ) ?? bundle.url(forResource: effect.rawValue, withExtension: "wav")
    }
}
