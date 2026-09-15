@MainActor
protocol GamePersisting: AnyObject {
    var bestScore: Int { get set }
    var hasSeenTutorial: Bool { get set }
    var settings: GameSettings { get set }
    var lastRunSeed: UInt64? { get set }
}
