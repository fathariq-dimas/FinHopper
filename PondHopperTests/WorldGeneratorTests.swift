import Testing
@testable import FinHopper

struct WorldGeneratorTests {
    private let generator = WorldGenerator(config: .live)

    @Test
    func smallPondsUseSpacedGapsAtEveryDifficulty() {
        let blueprint = generator.generate(seed: 42, rowCount: 240)
        #expect(GameConfig.live.difficulty(for: 0).pondGapRows == 9)
        #expect(GameConfig.live.difficulty(for: 1_000).pondGapRows == 12)
        let smallPonds = blueprint.ponds
        for (start, end) in zip(smallPonds, smallPonds.dropFirst()) {
            #expect(end.position.row - start.position.row == GameConfig.live.difficulty(for: start.position.row).pondGapRows)
        }
    }

    @Test
    func sameSeedProducesSameBlueprint() {
        let first = generator.generate(seed: 42, rowCount: 160)
        let second = generator.generate(seed: 42, rowCount: 160)

        #expect(first == second)
    }

    @Test
    func blueprintContainsAllPondsAndRepeatedRoadBlocksAtRunStart() {
        let blueprint = generator.generate(seed: 42, rowCount: 160)

        #expect(blueprint.ponds.count > 10)
        #expect(blueprint.roadLanes.count > 25)
        #expect(blueprint.ponds[0].position.row == 2)
        #expect(blueprint.ponds[0].position.column == GameConfig.live.columns / 2)
        #expect(blueprint.ponds[1].position.row == 11)
        #expect(blueprint.roadLanes.keys.filter { (3...10).contains($0) }.count == 2)
        #expect(blueprint.obstacles[GridPosition(column: 4, row: 1)] == nil)
    }

    @Test
    func firstSegmentStaticObstacleDensityStaysWithinFriendlyTarget() throws {
        for seed in 0..<100 {
            let blueprint = generator.generate(seed: UInt64(seed), rowCount: 24)
            let firstPond = try #require(blueprint.ponds.first)
            let targetPond = try #require(blueprint.ponds.dropFirst().first)
            let intermediateRows = (firstPond.position.row + 1)..<targetPond.position.row
            let grassRows = intermediateRows.filter { blueprint.roadLanes[$0] == nil }
            let obstacleCount = blueprint.obstacles.keys.filter { grassRows.contains($0.row) }.count
            let density = Double(obstacleCount) / Double(grassRows.count * GameConfig.live.columns)

            #expect(density >= 0.20, "Early obstacle density too low for seed \(seed)")
            #expect(density <= 0.30, "Early obstacle density too high for seed \(seed)")
        }
    }

    @Test
    func roadLaneSpeedVariationIsDeterministicAndBounded() throws {
        let first = generator.generate(seed: 42, rowCount: 160)
        let second = generator.generate(seed: 42, rowCount: 160)
        let firstTargetRow = try #require(first.ponds.dropFirst().first?.position.row)
        let initialLanes = first.roadLanes.values
            .filter { $0.row < firstTargetRow }
            .sorted { $0.row < $1.row }
        let initialSpeed = GameConfig.live.difficulty(for: 0).carSpeedInScreenWidths

        #expect(initialLanes.count == 2)
        #expect(first.roadLanes == second.roadLanes)
        #expect(Set(initialLanes.map(\.speedInScreenWidths)).count == initialLanes.count)

        for lane in initialLanes {
            #expect(lane.vehicleKind == .car)
            #expect(lane.speedInScreenWidths >= initialSpeed * 0.80)
            #expect(lane.speedInScreenWidths <= initialSpeed * 1.20)
        }
    }

    @Test
    func generatedRoutesValidateAcrossOneThousandSeedsAndEveryTier() {
        for seed in 0..<1_000 {
            let blueprint = generator.generate(seed: UInt64(seed), rowCount: 145)
            #expect(
                blueprint.validatedRouteCount == blueprint.ponds.count - 1,
                "Unvalidated pond route for seed \(seed)"
            )
        }
    }

    @Test
    func expandedBlueprintKeepsExistingPrefixStable() {
        let initial = generator.generate(seed: 99, rowCount: 96)
        let expanded = generator.generate(seed: 99, rowCount: 192)

        #expect(Array(expanded.rows.prefix(initial.rows.count)) == initial.rows)
        #expect(
            expanded.ponds.filter { $0.position.row <= initial.maximumRow } == initial.ponds
        )
        #expect(
            expanded.obstacles.filter { $0.key.row <= initial.maximumRow } == initial.obstacles
        )
        #expect(
            expanded.roadLanes.filter { $0.key <= initial.maximumRow } == initial.roadLanes
        )
    }
    @Test func largePondsAreRareAndNeverShareARowWithSmallPonds() {
        let world = generator.generate(seed: 42, rowCount: 240)
        let largePonds = world.ponds.filter { $0.kind == .large }
        #expect(!largePonds.isEmpty)
        #expect(Set(world.ponds.map { $0.position.row }).count == world.ponds.count)
        #expect(largePonds.count <= (world.ponds.count - 1) / 4)
        for large in largePonds {
            #expect(large.id.isMultiple(of: 4))
            #expect(world.obstacles[large.position] == nil)
            #expect(world.obstacles[large.position.moved(.down)] == .tree)
        }
    }
}
