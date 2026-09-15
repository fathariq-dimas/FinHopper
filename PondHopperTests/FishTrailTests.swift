import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct FishTrailTests {
    @Test
    func imprintKeepsTheFishOrientationFromBeforeEachHop() {
        let scene = makeScene()
        scene.setReduceMotion(true)
        scene.setGameplayRunning(true)
        for direction in [MoveDirection.left, .down, .right] {
            let beforeHop = scene.debugFishOrientation
            scene.enqueueMovement(direction)
            scene.debugFinishActiveMovement()
            #expect(scene.debugTrailScales.last == CGSize(
                width: beforeHop.horizontalScale, height: beforeHop.verticalScale
            ))
            #expect(scene.debugFishOrientation != beforeHop)
        }
    }

    @Test
    func marksFadeWithBothAgeAndDistance() {
        let near = FishTrailMarkNode(position: .init(column: 3, row: 2), orientation: FishSpriteOrientation(), tileSize: 56)
        let far = FishTrailMarkNode(position: .init(column: 3, row: 1), orientation: FishSpriteOrientation(), tileSize: 56)
        near.advance(by: 0, distanceFromFish: 1)
        far.advance(by: 0, distanceFromFish: 2)
        #expect(near.alpha > far.alpha)
        let initialOpacity = near.alpha
        near.advance(by: 0.8, distanceFromFish: 1)
        #expect(near.alpha > 0 && near.alpha < initialOpacity)
        near.advance(by: 0.8, distanceFromFish: 1)
        #expect(near.alpha == 0)
    }

    @Test
    func completedHopsKeepOnlyFourMarksAndBlockedMovesLeaveNone() {
        let scene = makeScene()
        scene.setGameplayRunning(true)
        for direction in [MoveDirection.left, .left, .left, .down, .right, .right] {
            scene.enqueueMovement(direction)
            scene.debugFinishActiveMovement()
        }
        #expect(scene.debugTrailPositions.count == 4)
        #expect(!scene.debugTrailPositions.contains(scene.debugPlayerGridPosition))

        scene.debugSetProgress(row: 0)
        let marks = scene.debugTrailPositions
        scene.enqueueMovement(.down)
        scene.debugFinishActiveMovement()
        #expect(scene.debugTrailPositions == marks)
    }

    @Test
    func pausedTrailFreezesThenExpiresAfterResuming() {
        let scene = makeScene()
        scene.setReduceMotion(true)
        scene.setGameplayRunning(true)
        scene.enqueueMovement(.left)
        scene.debugFinishActiveMovement()
        #expect(scene.debugTrailPositions.count == 1)
        let opacity = scene.debugTrailOpacities
        scene.setSimulationPaused(true)
        scene.update(1)
        scene.update(10)
        #expect(scene.debugTrailOpacities == opacity)

        scene.setGameplayRunning(true)
        scene.update(11)
        for frame in 1...100 { scene.update(11 + Double(frame) / 60) }
        #expect(scene.debugTrailPositions.isEmpty)
    }

    @Test
    func revisitsDoNotStackMarksAndResizeClearsTransientTrail() {
        let scene = makeScene()
        scene.setGameplayRunning(true)
        for direction in [MoveDirection.left, .right, .left, .right] {
            scene.enqueueMovement(direction)
            scene.debugFinishActiveMovement()
        }
        #expect(scene.debugTrailPositions.count == 1)
        scene.size = CGSize(width: 430, height: 932)
        #expect(scene.debugTrailPositions.isEmpty)
    }

    private func makeScene() -> GameScene {
        let scene = GameScene(config: .live, seed: 42, eventSink: RecordingGameSceneEventSink())
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        return scene
    }
}
