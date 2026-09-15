@testable import FinHopper

@MainActor
final class MemoryGamePersistence: GamePersisting {
    var bestScore = 0
    var hasSeenTutorial = false
    var settings = GameSettings.defaults
    var lastRunSeed: UInt64?
}
