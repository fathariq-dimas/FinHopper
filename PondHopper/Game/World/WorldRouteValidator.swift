import Foundation

nonisolated struct WorldRouteValidator: Sendable {
    let config: GameConfig

    func canReach(
        from start: GridPosition,
        to target: GridPosition,
        obstacles: Set<GridPosition>,
        roadLanes: [Int: RoadLaneDefinition]
    ) -> Bool {
        let representativePeriod = roadLanes.values.map(\.spawnInterval).max() ?? 1
        let phaseSamples = [0.0, 0.25, 0.5, 0.75].map { $0 * representativePeriod }

        return phaseSamples.allSatisfy { startTime in
            canReach(
                from: start,
                to: target,
                obstacles: obstacles,
                roadLanes: roadLanes,
                startTime: startTime
            )
        }
    }

    private func canReach(
        from start: GridPosition,
        to target: GridPosition,
        obstacles: Set<GridPosition>,
        roadLanes: [Int: RoadLaneDefinition],
        startTime: Double
    ) -> Bool {
        let stepDuration = max(0.08, config.movementDuration)
        let maximumTicks = Int(floor(min(5, config.maximumBreath) / stepDuration))
        let actions: [MoveDirection?] = [nil, .up, .down, .left, .right]
        var frontier: Set<GridPosition> = [start]

        for tick in 0...maximumTicks {
            if frontier.contains(target) {
                return true
            }

            let transitionStart = startTime + (Double(tick) * stepDuration)
            var nextFrontier: Set<GridPosition> = []

            for position in frontier {
                for action in actions {
                    let destination = action.map(position.moved) ?? position

                    guard (0..<config.columns).contains(destination.column) else { continue }
                    guard destination.row >= start.row else { continue }
                    guard destination.row <= target.row else { continue }
                    guard !obstacles.contains(destination) else { continue }
                    guard transitionIsSafe(
                        from: position,
                        to: destination,
                        startTime: transitionStart,
                        duration: stepDuration,
                        roadLanes: roadLanes
                    ) else { continue }

                    nextFrontier.insert(destination)
                }
            }

            guard !nextFrontier.isEmpty else { return false }
            frontier = nextFrontier
        }

        return false
    }

    private func transitionIsSafe(
        from source: GridPosition,
        to destination: GridPosition,
        startTime: Double,
        duration: Double,
        roadLanes: [Int: RoadLaneDefinition]
    ) -> Bool {
        let samples = [0.0, 0.5, 1.0]

        return samples.allSatisfy { progress in
            let time = startTime + (duration * progress)
            let interpolatedColumn = Double(source.column)
                + (Double(destination.column - source.column) * progress)
            let sampledRows = Set([source.row, destination.row])

            return sampledRows.allSatisfy { row in
                guard let lane = roadLanes[row] else { return true }
                return !lane.isOccupied(
                    column: interpolatedColumn + 0.5,
                    at: time,
                    columnCount: config.columns
                )
            }
        }
    }
}
