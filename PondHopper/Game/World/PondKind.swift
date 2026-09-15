nonisolated enum PondKind: Equatable, Sendable {
    case small, large

    var addedSeconds: Double { self == .small ? 5 : 10 }
    var visualScale: Double { self == .small ? 2.1 : 2.8 }
}
