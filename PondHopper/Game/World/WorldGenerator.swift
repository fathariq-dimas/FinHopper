nonisolated struct WorldGenerator: Sendable {
    static let initialRowCount = 512

    private struct SegmentCandidate {
        let targetPond: GeneratedPond
        let roadLanes: [Int: RoadLaneDefinition]
        let obstacles: [GridPosition: StaticObstacleKind]
    }

    let config: GameConfig

    func generate(
        seed: UInt64,
        rowCount: Int = WorldGenerator.initialRowCount
    ) -> WorldBlueprint {
        let safeRowCount = max(24, rowCount)
        let maximumRow = safeRowCount - 1
        var random = SeededRandomNumberGenerator(seed: seed)
        var rows = (0...maximumRow).map { index in
            GeneratedRow(index: index, terrain: index.isMultiple(of: 4) ? .meadow : .grass)
        }
        let startingRow = 2
        var ponds = [
            GeneratedPond(
                id: 0,
                position: GridPosition(column: config.columns / 2, row: startingRow)
            )
        ]
        var obstacles: [GridPosition: StaticObstacleKind] = [:]
        var roadLanes: [Int: RoadLaneDefinition] = [:]
        var validatedRouteCount = 0
        var fallbackChunkCount = 0

        rows[startingRow].terrain = .pondClearing

        var startPond = ponds[0]
        var segmentIndex = 0
        while !Task.isCancelled {
            let difficulty = config.difficulty(for: startPond.position.row)
            let targetRow = startPond.position.row + difficulty.pondGapRows
            guard targetRow <= maximumRow else { break }

            var acceptedCandidate: SegmentCandidate?

            for _ in 0..<8 {
                let candidate = makeCandidate(
                    from: startPond,
                    targetID: ponds.count,
                    targetRow: targetRow,
                    difficulty: difficulty,
                    random: &random
                )
                let validator = WorldRouteValidator(config: config)

                if validator.canReach(
                    from: startPond.position,
                    to: candidate.targetPond.position,
                    obstacles: Set(candidate.obstacles.keys),
                    roadLanes: candidate.roadLanes
                ) {
                    acceptedCandidate = candidate
                    validatedRouteCount += 1
                    break
                }
            }

            let candidate: SegmentCandidate
            if let acceptedCandidate {
                candidate = acceptedCandidate
            } else {
                candidate = makeFallbackCandidate(
                    from: startPond,
                    targetID: ponds.count,
                    targetRow: targetRow,
                    difficulty: difficulty
                )
                fallbackChunkCount += 1

                let validator = WorldRouteValidator(config: config)
                if validator.canReach(
                    from: startPond.position,
                    to: candidate.targetPond.position,
                    obstacles: [],
                    roadLanes: candidate.roadLanes
                ) {
                    validatedRouteCount += 1
                }
            }

            ponds.append(candidate.targetPond)
            candidate.obstacles.forEach { obstacles[$0.key] = $0.value }
            candidate.roadLanes.forEach { row, lane in
                roadLanes[row] = lane
                rows[row].terrain = .road
            }
            rows[targetRow].terrain = .pondClearing
            segmentIndex += 1
            var nextPond = candidate.targetPond
            if segmentIndex.isMultiple(of: 4), config.columns >= 7 {
                let column = candidate.targetPond.position.column
                let inward = column < config.columns / 2 ? 1 : -1
                let large = GeneratedPond(id: candidate.targetPond.id,
                    position: candidate.targetPond.position, kind: .large)
                var branchObstacles = obstacles
                // Require a side approach, without offering a second refill on this row.
                branchObstacles[large.position.moved(.down)] = .tree
                branchObstacles[GridPosition(column: column + inward, row: targetRow)] = nil
                branchObstacles[GridPosition(column: column + inward, row: targetRow - 1)] = nil
                let validator = WorldRouteValidator(config: config)
                if validator.canReach(from: startPond.position, to: large.position,
                    obstacles: Set(branchObstacles.keys), roadLanes: candidate.roadLanes) {
                    ponds[ponds.count - 1] = large
                    obstacles = branchObstacles
                    nextPond = large
                }
            }
            startPond = nextPond
        }

        let generatedMaximumRow = ponds.last?.position.row ?? 0
        rows = Array(rows.prefix(generatedMaximumRow + 1))

        return WorldBlueprint(
            seed: seed,
            rows: rows,
            obstacles: obstacles,
            ponds: ponds,
            roadLanes: roadLanes,
            validatedRouteCount: validatedRouteCount,
            fallbackChunkCount: fallbackChunkCount
        )
    }

    private func makeCandidate(
        from startPond: GeneratedPond,
        targetID: Int,
        targetRow: Int,
        difficulty: DifficultyParameters,
        random: inout SeededRandomNumberGenerator
    ) -> SegmentCandidate {
        let laneCount = min(difficulty.maximumRoadLanes, targetRow - startPond.position.row - 4)
        let earliestRoadRow = startPond.position.row + 2
        let latestRoadRow = max(earliestRoadRow, targetRow - laneCount - 1)
        let roadStart = random.integer(in: earliestRoadRow...latestRoadRow)
        let roadRange = roadStart..<(roadStart + laneCount)
        let maximumColumnShift = difficulty.tier == 0 ? 1 : min(3, 1 + (difficulty.tier / 2))
        let lowerColumn = max(0, startPond.position.column - maximumColumnShift)
        let upperColumn = min(config.columns - 1, startPond.position.column + maximumColumnShift)
        let targetColumn = random.integer(in: lowerColumn...upperColumn)
        let targetPond = GeneratedPond(
            id: targetID,
            position: GridPosition(column: targetColumn, row: targetRow)
        )
        let lanes = makeRoadLanes(
            rows: roadRange,
            difficulty: difficulty,
            random: &random
        )
        let protectedRoute = makeProtectedRoute(
            from: startPond.position,
            to: targetPond.position,
            roadRows: Set(roadRange)
        )
        let obstacles = makeObstacles(
            fromRow: startPond.position.row + 1,
            throughRow: targetRow - 1,
            difficulty: difficulty,
            roadRows: Set(roadRange),
            protectedRoute: protectedRoute,
            random: &random
        )

        return SegmentCandidate(
            targetPond: targetPond,
            roadLanes: lanes,
            obstacles: obstacles
        )
    }

    private func makeRoadLanes(
        rows: Range<Int>,
        difficulty: DifficultyParameters,
        random: inout SeededRandomNumberGenerator
    ) -> [Int: RoadLaneDefinition] {
        var lanes: [Int: RoadLaneDefinition] = [:]
        let firstDirection: VehicleTravelDirection = random.chance(0.5) ? .right : .left

        for (offset, row) in rows.enumerated() {
            let direction: VehicleTravelDirection = offset.isMultiple(of: 2)
                ? firstDirection
                : (firstDirection == .right ? .left : .right)
            let kind: VehicleKind = difficulty.tier >= 2 && random.chance(0.28) ? .truck : .car
            let baseSpeed = kind == .car
                ? difficulty.carSpeedInScreenWidths
                : difficulty.truckSpeedInScreenWidths
            let speed = baseSpeed * random.double(in: 0.80...1.20)

            lanes[row] = RoadLaneDefinition(
                row: row,
                direction: direction,
                vehicleKind: kind,
                speedInScreenWidths: speed,
                spawnInterval: difficulty.spawnInterval,
                phaseOffset: random.double(in: 0...difficulty.spawnInterval)
            )
        }

        return lanes
    }

    private func makeObstacles(
        fromRow firstRow: Int,
        throughRow lastRow: Int,
        difficulty: DifficultyParameters,
        roadRows: Set<Int>,
        protectedRoute: Set<GridPosition>,
        random: inout SeededRandomNumberGenerator
    ) -> [GridPosition: StaticObstacleKind] {
        guard firstRow <= lastRow else { return [:] }

        var obstacles: [GridPosition: StaticObstacleKind] = [:]
        let minimumPerGrassRow = difficulty.tier <= 1 ? 2 : 1
        let maximumPerGrassRow = max(
            minimumPerGrassRow,
            min(4, 2 + (difficulty.tier / 2))
        )

        for row in firstRow...lastRow where !roadRows.contains(row) {
            let desiredCount = random.integer(in: minimumPerGrassRow...maximumPerGrassRow)
            var candidates = (0..<config.columns).map { GridPosition(column: $0, row: row) }
            candidates.removeAll { position in
                protectedRoute.contains(position)
                    || (difficulty.tier <= 1 && protectedRoute.contains {
                        $0.row == row && abs($0.column - position.column) <= 1
                    })
            }
            candidates.shuffle(using: &random)

            for position in candidates.prefix(desiredCount) {
                obstacles[position] = random.chance(0.58) ? .tree : .log
            }
        }

        return obstacles
    }

    private func makeProtectedRoute(
        from start: GridPosition,
        to target: GridPosition,
        roadRows: Set<Int>
    ) -> Set<GridPosition> {
        var route: Set<GridPosition> = [start, target]
        var column = start.column

        guard start.row < target.row else { return route }

        for row in (start.row + 1)...target.row {
            let previousColumn = column

            if !roadRows.contains(row), column != target.column {
                column += column < target.column ? 1 : -1
            }

            route.insert(GridPosition(column: previousColumn, row: row))
            route.insert(GridPosition(column: column, row: row))
        }

        return route
    }

    private func makeFallbackCandidate(
        from startPond: GeneratedPond,
        targetID: Int,
        targetRow: Int,
        difficulty: DifficultyParameters
    ) -> SegmentCandidate {
        let targetPond = GeneratedPond(
            id: targetID,
            position: GridPosition(column: startPond.position.column, row: targetRow)
        )
        let laneCount = min(difficulty.maximumRoadLanes, targetRow - startPond.position.row - 4)
        let roadStart = startPond.position.row + 2
        var lanes: [Int: RoadLaneDefinition] = [:]

        for offset in 0..<laneCount {
            let row = roadStart + offset
            let direction: VehicleTravelDirection = offset.isMultiple(of: 2) ? .right : .left
            let speedMultiplier = [0.85, 1.0, 1.15][offset % 3]
            lanes[row] = RoadLaneDefinition(
                row: row,
                direction: direction,
                vehicleKind: .car,
                speedInScreenWidths: difficulty.carSpeedInScreenWidths * speedMultiplier,
                spawnInterval: difficulty.spawnInterval,
                phaseOffset: (Double(offset) / Double(max(1, laneCount))) * difficulty.spawnInterval
            )
        }

        return SegmentCandidate(
            targetPond: targetPond,
            roadLanes: lanes,
            obstacles: [:]
        )
    }
}
