#if DEBUG
nonisolated struct GameSceneDiagnostics: Equatable, Sendable {
    let renderedRowCount: Int
    let vehicleNodeCount: Int
    let worldChildCount: Int
    let blueprintRowCount: Int
}
#endif
