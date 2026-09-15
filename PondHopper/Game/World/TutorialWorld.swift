nonisolated enum TutorialWorld {
    static let offset = 10
    static let pondRow = offset + 2

    static func prepend(to world: WorldBlueprint, columns: Int) -> WorldBlueprint {
        let center = columns / 2
        var rows = (0..<offset).map { GeneratedRow(index: $0, terrain: .grass) }
        rows[6].terrain = .road
        rows += world.rows.map { GeneratedRow(index: $0.index + offset, terrain: $0.terrain) }
        var obstacles = Dictionary(uniqueKeysWithValues: world.obstacles.map {
            (GridPosition(column: $0.key.column, row: $0.key.row + offset), $0.value)
        })
        for row in 1..<offset where row != 6 {
            for column in [center - 2, center + 2] {
                obstacles[GridPosition(column: column, row: row)] = .tree
            }
        }
        obstacles[GridPosition(column: center, row: 4)] = .tree
        obstacles[GridPosition(column: center - 1, row: 4)] = .tree
        var lanes = Dictionary(uniqueKeysWithValues: world.roadLanes.values.map { lane in
            (lane.row + offset, RoadLaneDefinition(row: lane.row + offset,
                direction: lane.direction, vehicleKind: lane.vehicleKind,
                speedInScreenWidths: lane.speedInScreenWidths, spawnInterval: lane.spawnInterval,
                phaseOffset: lane.phaseOffset))
        })
        lanes[6] = RoadLaneDefinition(row: 6, direction: .right, vehicleKind: .car,
            speedInScreenWidths: 0.20, spawnInterval: 3.6, phaseOffset: 0)
        return WorldBlueprint(seed: world.seed, rows: rows, obstacles: obstacles,
            ponds: world.ponds.map { GeneratedPond(id: $0.id,
                position: GridPosition(column: $0.position.column, row: $0.position.row + offset), kind: $0.kind) },
            roadLanes: lanes, validatedRouteCount: world.validatedRouteCount,
            fallbackChunkCount: world.fallbackChunkCount)
    }
}
