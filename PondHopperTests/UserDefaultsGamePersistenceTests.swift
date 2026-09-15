import Foundation
import Testing
@testable import FinHopper

@MainActor
struct UserDefaultsGamePersistenceTests {
    @Test
    func roundTripsSavedValues() throws {
        let suiteName = "FinHopperTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let persistence = UserDefaultsGamePersistence(defaults: defaults)

        persistence.bestScore = 42
        persistence.hasSeenTutorial = true
        persistence.settings = GameSettings(
            soundEnabled: false,
            hapticsEnabled: true,
            showsDirectionalPad: true
        )
        persistence.lastRunSeed = UInt64.max

        #expect(persistence.bestScore == 42)
        #expect(persistence.hasSeenTutorial)
        #expect(!persistence.settings.soundEnabled)
        #expect(persistence.settings.hapticsEnabled)
        #expect(persistence.settings.showsDirectionalPad)
        #expect(persistence.lastRunSeed == UInt64.max)
    }
}
