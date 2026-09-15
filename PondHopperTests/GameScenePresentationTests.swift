import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct GameScenePresentationTests {
    @Test
    func fishGrowsVisuallyWithoutChangingCollisionFootprint() {
        let scene = makeScene()

        #expect(scene.debugPlayerGridPosition.column == GameConfig.live.columns / 2)
        #expect(abs(scene.debugPlayerVisualScaleInTiles - 1.50) < 0.001)
        #expect(abs(scene.debugPlayerCollisionSizeInTiles.width - 0.53) < 0.001)
        #expect(abs(scene.debugPlayerCollisionSizeInTiles.height - 0.46) < 0.001)
    }

    @Test
    func loadsTheUnifiedElevenFrameFishSequence() {
        let scene = makeScene()

        #expect(scene.debugFishTextureCount == FishAnimationContract.frameCount)
        #expect(scene.debugHasFishRestingAnimation)
        #expect(scene.debugFishOrientation == FishSpriteOrientation())
    }

    @Test
    func bundledAtlasContainsExactlyTheElevenV5FishFrames() {
        let bundledFishNames = Set(
            (Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? [])
                .compactMap { url -> String? in
                    let name = url.deletingPathExtension().lastPathComponent
                    return name.hasPrefix("fish-") ? name : nil
                }
        )
        let expectedFishNames = Set(
            (1...FishAnimationContract.frameCount).map { "fish-flop-\($0)" }
        )

        #expect(expectedFishNames.count == 11)
        #expect(bundledFishNames == expectedFishNames)
    }

    @Test
    func acceptedVerticalMovementFlipsOnlyTheVerticalOrientation() {
        let scene = makeScene()

        scene.setGameplayRunning(true)
        scene.enqueueMovement(.up)

        #expect(!scene.debugFishOrientation.isHorizontallyFlipped)
        #expect(scene.debugFishOrientation.isVerticallyFlipped)
        #expect(!scene.debugHasFishRestingAnimation)
    }

    @Test
    func acceptedHorizontalMovementFlipsOnlyTheHorizontalOrientation() {
        let scene = makeScene()

        scene.setGameplayRunning(true)
        scene.enqueueMovement(.right)

        #expect(scene.debugFishOrientation.isHorizontallyFlipped)
        #expect(!scene.debugFishOrientation.isVerticallyFlipped)
        #expect(!scene.debugHasFishRestingAnimation)
    }

    @Test
    func blockedMovementDoesNotChangeOrientation() {
        let scene = makeScene()
        scene.debugSetProgress(row: 0)
        let orientationBeforeMovement = scene.debugFishOrientation

        scene.setGameplayRunning(true)
        scene.enqueueMovement(.down)

        #expect(scene.debugFishOrientation == orientationBeforeMovement)
    }

    @Test
    func reduceMotionKeepsTheFishOnAStaticFrame() {
        let scene = makeScene()

        scene.setReduceMotion(true)

        #expect(scene.debugFishTextureCount == 11)
        #expect(!scene.debugHasFishRestingAnimation)
    }

    @Test
    func drainedStartingPondRemainsVisibleWhileBreathDecreases() {
        let scene = makeScene()
        #expect(scene.debugPondIsVisited(id: 0))
        #expect(scene.debugPondIsDrained(id: 0))
        #expect(scene.debugPlayerRestingAnimationState == .landIdle)

        scene.setGameplayRunning(true)
        scene.update(1)
        for frame in 1...240 {
            scene.update(1 + Double(frame) / 60)
        }

        #expect(scene.debugRenderedPondIDs.contains(0))
        #expect(scene.debugPondIsDrained(id: 0))
        #expect(abs(scene.debugRemainingBreath - 6) < 0.01)
    }

    @Test
    func pondRefillsOnlyOnceAndStaysDrainedAfterVisualRebuild() throws {
        let scene = makeScene()
        let pondID = try #require(scene.debugRenderedPondIDs.first {
            !scene.debugPondIsVisited(id: $0)
        })
        #expect(!scene.debugPondIsDrained(id: pondID))
        scene.setGameplayRunning(true)
        scene.update(1)
        scene.update(1.05)
        #expect(scene.debugRemainingBreath < GameConfig.live.maximumBreath)

        scene.debugVisitPond(id: pondID)
        #expect(scene.debugRemainingBreath == GameConfig.live.maximumBreath)
        #expect(scene.debugPondIsDrained(id: pondID))
        scene.update(1.10)
        let breathAfterConsumption = scene.debugRemainingBreath
        scene.debugVisitPond(id: pondID)
        #expect(scene.debugRemainingBreath == breathAfterConsumption)

        scene.size = CGSize(width: 430, height: 932)
        scene.setReduceMotion(true)
        scene.setReduceMotion(false)
        #expect(scene.debugPondIsDrained(id: pondID))
    }

    private func makeScene() -> GameScene {
        let eventSink = RecordingGameSceneEventSink()
        let scene = GameScene(config: .live, seed: 42, eventSink: eventSink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        return scene
    }
}
