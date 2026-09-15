nonisolated extension MoveDirection {
    var accessibilityName: String {
        switch self {
        case .up:
            "Up"
        case .down:
            "Down"
        case .left:
            "Left"
        case .right:
            "Right"
        }
    }
}
