import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct HopProtectionTests {
    @Test
    func validHopsIgnoreCrossingVehiclesInEveryDirection() {
        for direction in [MoveDirection.up, .down, .left, .right] {
            let scene = makeScene()
            scene.enqueueMovement(direction)
            #expect(scene.debugIsHopProtected)
            scene.debugOverlapVehicleWithPlayer()
            scene.debugCheckVehicleCollision()
            #expect(!scene.debugDidEndRun)
        }
    }

    @Test
    func landingCollisionWinsOverQueuedMovement() {
        let scene = makeScene()
        scene.enqueueMovement(.left)
        scene.enqueueMovement(.right)
        scene.debugFinishActiveMovement(overlappingVehicle: true)
        #expect(scene.debugDidEndRun)
        #expect(!scene.debugIsHopProtected)
    }

    @Test
    func safeLandingClearsProtectionAndOldCollisionHistory() {
        let scene = makeScene()
        scene.enqueueMovement(.up)
        scene.debugOverlapVehicleWithPlayer()
        scene.debugFinishActiveMovement()
        scene.debugCheckVehicleCollision()
        #expect(!scene.debugDidEndRun)
        #expect(!scene.debugIsHopProtected)
    }

    @Test
    func stationaryAndBlockedFishRemainVulnerable() {
        for blocked in [false, true] {
            let scene = makeScene()
            if blocked {
                scene.debugSetProgress(row: 0)
                scene.enqueueMovement(.down)
            }
            #expect(!scene.debugIsHopProtected)
            scene.debugOverlapVehicleWithPlayer()
            scene.debugCheckVehicleCollision()
            #expect(scene.debugDidEndRun)
        }
    }

    @Test
    func pausePreservesProtectionAndBreathStillRunsAfterResume() {
        let scene = makeScene()
        scene.setReduceMotion(true)
        scene.enqueueMovement(.left)
        scene.setSimulationPaused(true)
        scene.update(1)
        scene.update(2)
        #expect(scene.debugIsHopProtected)
        let breath = scene.debugRemainingBreath
        scene.setSimulationPaused(false)
        scene.update(3)
        scene.update(3.05)
        #expect(scene.debugRemainingBreath < breath)
        scene.debugFinishActiveMovement()
        #expect(!scene.debugIsHopProtected)
    }

    @Test
    func zeroDurationLandingAndResizeClearProtection() {
        let config = GameConfig(columns: 7, movementDuration: 0, maximumBreath: 10,
            countdownSeconds: 3, rowsPerDifficultyTier: 20, maximumDifficultyTier: 6)
        let scene = makeScene(config: config)
        scene.enqueueMovement(.left)
        scene.debugFinishActiveMovement(overlappingVehicle: true)
        #expect(scene.debugDidEndRun)
        #expect(!scene.debugIsHopProtected)

        let resized = makeScene()
        resized.enqueueMovement(.left)
        resized.size = CGSize(width: 430, height: 932)
        #expect(!resized.debugIsHopProtected)
    }

    private func makeScene(config: GameConfig = .live) -> GameScene {
        let scene = GameScene(config: config, seed: 42, eventSink: RecordingGameSceneEventSink())
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        scene.setGameplayRunning(true)
        return scene
    }
}
