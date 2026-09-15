nonisolated enum VehicleTravelDirection: Int, Equatable, Sendable {
    case left = -1
    case right = 1

    var multiplier: Double {
        Double(rawValue)
    }
}
