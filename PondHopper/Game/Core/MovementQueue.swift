nonisolated struct MovementQueue: Equatable, Sendable {
    private(set) var activeDirection: MoveDirection?
    private(set) var bufferedDirection: MoveDirection?

    @discardableResult
    mutating func enqueue(_ direction: MoveDirection) -> MoveDirection? {
        guard activeDirection == nil else {
            if bufferedDirection == nil {
                bufferedDirection = direction
            }
            return nil
        }

        activeDirection = direction
        return direction
    }

    mutating func completeActiveMovement() -> MoveDirection? {
        activeDirection = bufferedDirection
        bufferedDirection = nil
        return activeDirection
    }

    mutating func reset() {
        activeDirection = nil
        bufferedDirection = nil
    }
}
