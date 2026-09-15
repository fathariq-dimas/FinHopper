import Testing
@testable import FinHopper

struct FishSpriteOrientationTests {
    @Test(arguments: [MoveDirection.up, .down])
    func verticalMovementTogglesOnlyVerticalFlip(direction: MoveDirection) {
        var orientation = FishSpriteOrientation()

        orientation.applyMovement(direction, isAccepted: true)

        #expect(!orientation.isHorizontallyFlipped)
        #expect(orientation.isVerticallyFlipped)
    }

    @Test(arguments: [MoveDirection.left, .right])
    func horizontalMovementTogglesOnlyHorizontalFlip(direction: MoveDirection) {
        var orientation = FishSpriteOrientation()

        orientation.applyMovement(direction, isAccepted: true)

        #expect(orientation.isHorizontallyFlipped)
        #expect(!orientation.isVerticallyFlipped)
    }

    @Test
    func twoMovementsOnTheSameAxisRestoreThePreviousOrientation() {
        var orientation = FishSpriteOrientation()

        orientation.applyMovement(.up, isAccepted: true)
        orientation.applyMovement(.down, isAccepted: true)
        orientation.applyMovement(.left, isAccepted: true)
        orientation.applyMovement(.right, isAccepted: true)

        #expect(orientation == FishSpriteOrientation())
    }

    @Test
    func rejectedMovementDoesNotChangeOrientation() {
        var orientation = FishSpriteOrientation()

        orientation.applyMovement(.up, isAccepted: false)
        orientation.applyMovement(.right, isAccepted: false)

        #expect(orientation == FishSpriteOrientation())
    }

    @Test
    func idleAnimationContractMatchesTheApprovedCadence() {
        #expect(FishAnimationContract.frameCount == 11)
        #expect(FishAnimationContract.idleLoopsPerOrientation == 3)
        #expect(abs(FishAnimationContract.frameDuration - 0.12) < 0.000_1)
        #expect(abs(FishAnimationContract.idleHoldDuration - 1.2) < 0.000_1)
        #expect(abs(FishAnimationContract.fullIdleCycleDuration - 10.32) < 0.000_1)
    }
}
