nonisolated enum VehicleKind: Equatable, Sendable {
    case car
    case truck

    var lengthInColumns: Double {
        switch self {
        case .car:
            1.76
        case .truck:
            2.25
        }
    }
}
