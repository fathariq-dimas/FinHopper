@MainActor
protocol GameAudioPlaying: AnyObject {
    func preload()
    func play(_ effect: GameSoundEffect)
}
