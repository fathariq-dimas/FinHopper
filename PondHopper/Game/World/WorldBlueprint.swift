nonisolated struct WorldBlueprint: Equatable, Sendable {
    let seed: UInt64
    let rows: [GeneratedRow]
    let obstacles: [GridPosition: StaticObstacleKind]
    let ponds: [GeneratedPond]
    let roadLanes: [Int: RoadLaneDefinition]
    let validatedRouteCount: Int
    let fallbackChunkCount: Int

    var maximumRow: Int {
        rows.last?.index ?? 0
    }

    func row(at index: Int) -> GeneratedRow? {
        guard rows.indices.contains(index) else { return nil }
        return rows[index]
    }

    func pond(at position: GridPosition) -> GeneratedPond? {
        ponds.first { $0.position == position }
    }

    func pond(id: Int) -> GeneratedPond? {
        ponds.first { $0.id == id }
    }
}
