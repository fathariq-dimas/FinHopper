import Testing
@testable import FinHopper

struct VehiclePassByTrackerTests {
    private let first = VehicleSpawnKey(row: 5, spawnIndex: 0)
    private let second = VehicleSpawnKey(row: 6, spawnIndex: 0)

    @Test
    func includesAdjacentLaneButExcludesDistantTraffic() {
        #expect(VehiclePassByTracker.isNearby(horizontalTiles: 2, verticalRows: 0))
        #expect(VehiclePassByTracker.isNearby(horizontalTiles: -2, verticalRows: -1))
        #expect(!VehiclePassByTracker.isNearby(horizontalTiles: 2.3, verticalRows: 1))
        #expect(!VehiclePassByTracker.isNearby(horizontalTiles: 0, verticalRows: 2))
    }

    @Test
    func eachVehicleSoundsOnceEvenWhenFishMovesOutAndBack() {
        var tracker = VehiclePassByTracker()
        let played1 = tracker.shouldPlay(nearbyKeys: [], activeKeys: [first], at: 0)
        #expect(!played1)
        let played2 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first], at: 1)
        #expect(played2)
        let played3 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first], at: 1.1)
        #expect(!played3)
        let played4 = tracker.shouldPlay(nearbyKeys: [], activeKeys: [first], at: 2)
        #expect(!played4)
        let played5 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first], at: 3)
        #expect(!played5)
    }

    @Test
    func busyTrafficDoesNotQueueOrOverlapSounds() {
        var tracker = VehiclePassByTracker()
        let played6 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first, second], at: 0)
        #expect(played6)
        let played7 = tracker.shouldPlay(nearbyKeys: [second], activeKeys: [first, second], at: 0.5)
        #expect(!played7)
        let played8 = tracker.shouldPlay(nearbyKeys: [second], activeKeys: [second], at: 2)
        #expect(!played8)
        let next = VehicleSpawnKey(row: 5, spawnIndex: 1)
        let played9 = tracker.shouldPlay(nearbyKeys: [next], activeKeys: [second, next], at: 3)
        #expect(played9)
    }

    @Test
    func streamedOutVehiclesReleaseTheirTrackingState() {
        var tracker = VehiclePassByTracker()
        let played10 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first], at: 0)
        #expect(played10)
        let played11 = tracker.shouldPlay(nearbyKeys: [], activeKeys: [], at: 1)
        #expect(!played11)
        let played12 = tracker.shouldPlay(nearbyKeys: [first], activeKeys: [first], at: 3)
        #expect(played12)
    }
}
