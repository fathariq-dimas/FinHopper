import Foundation

@MainActor
final class UserDefaultsGamePersistence: GamePersisting {
    private static let bestScoreKey = "bestScore"
    private static let hasSeenTutorialKey = "hasSeenTutorial"
    private static let soundEnabledKey = "soundEnabled"
    private static let hapticsEnabledKey = "hapticsEnabled"
    private static let directionalPadKey = "showsDirectionalPad"
    private static let lastRunSeedKey = "lastRunSeed"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var bestScore: Int {
        get { defaults.integer(forKey: Self.bestScoreKey) }
        set { defaults.set(max(0, newValue), forKey: Self.bestScoreKey) }
    }

    var hasSeenTutorial: Bool {
        get { defaults.bool(forKey: Self.hasSeenTutorialKey) }
        set { defaults.set(newValue, forKey: Self.hasSeenTutorialKey) }
    }

    var settings: GameSettings {
        get {
            GameSettings(
                soundEnabled: storedBoolean(forKey: Self.soundEnabledKey, fallback: true),
                hapticsEnabled: storedBoolean(forKey: Self.hapticsEnabledKey, fallback: true),
                showsDirectionalPad: storedBoolean(forKey: Self.directionalPadKey, fallback: false)
            )
        }
        set {
            defaults.set(newValue.soundEnabled, forKey: Self.soundEnabledKey)
            defaults.set(newValue.hapticsEnabled, forKey: Self.hapticsEnabledKey)
            defaults.set(newValue.showsDirectionalPad, forKey: Self.directionalPadKey)
        }
    }

    var lastRunSeed: UInt64? {
        get {
            guard let storedValue = defaults.string(forKey: Self.lastRunSeedKey) else {
                return nil
            }
            return UInt64(storedValue)
        }
        set {
            defaults.set(newValue.map(String.init), forKey: Self.lastRunSeedKey)
        }
    }

    private func storedBoolean(forKey key: String, fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }
        return defaults.bool(forKey: key)
    }
}
