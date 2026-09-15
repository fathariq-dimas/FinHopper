nonisolated struct VehiclePassByTracker {
    private var heardVehicleKeys: Set<VehicleSpawnKey> = []
    private var nextAllowedTime = 0.0

    // The bundled pass lasts 2.2 seconds; leave a small gap between passes.
    static let cooldown = 2.3

    static func isNearby(horizontalTiles: Double, verticalRows: Double) -> Bool {
        abs(horizontalTiles) <= 2.25 && abs(verticalRows) <= 1.15
    }

    mutating func shouldPlay(
        nearbyKeys: Set<VehicleSpawnKey>,
        activeKeys: Set<VehicleSpawnKey>,
        at time: Double
    ) -> Bool {
        heardVehicleKeys.formIntersection(activeKeys)
        let newKeys = nearbyKeys.intersection(activeKeys).subtracting(heardVehicleKeys)
        // Consume even suppressed passes, so traffic cannot queue a burst later.
        heardVehicleKeys.formUnion(newKeys)
        guard !newKeys.isEmpty, time >= nextAllowedTime else { return false }
        nextAllowedTime = time + Self.cooldown
        return true
    }
}
