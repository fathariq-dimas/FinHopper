nonisolated struct FishSpriteOrientation: Equatable, Sendable {
    private(set) var isHorizontallyFlipped = false
    private(set) var isVerticallyFlipped = false

    var horizontalScale: Double {
        isHorizontallyFlipped ? -1 : 1
    }

    var verticalScale: Double {
        isVerticallyFlipped ? -1 : 1
    }

    mutating func applyMovement(_ movement: MoveDirection, isAccepted: Bool) {
        guard isAccepted else { return }

        switch movement {
        case .up, .down:
            toggleVertically()
        case .left, .right:
            isHorizontallyFlipped.toggle()
        }
    }

    mutating func toggleVertically() {
        isVerticallyFlipped.toggle()
    }
}

nonisolated enum FishAnimationContract {
    static let frameCount = 11
    static let idleLoopsPerOrientation = 3
    static let frameDuration = 0.12
    static let idleHoldDuration = 1.2

    static var fullIdleCycleDuration: Double {
        let animatedBlockDuration = Double(frameCount * idleLoopsPerOrientation) * frameDuration
        return (animatedBlockDuration + idleHoldDuration) * 2
    }
}
