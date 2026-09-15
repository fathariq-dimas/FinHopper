import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct GameplayUpdateTests {
    @Test func cameraStartsFollowingOnFourthRowAndNeverMovesBack() {
        for size in [CGSize(width: 390, height: 844), CGSize(width: 430, height: 932)] {
            let sink = RecordingGameSceneEventSink()
            let scene = GameScene(config: .live, seed: 42, eventSink: sink)
            let view = SKView(frame: CGRect(origin: .zero, size: size))
            view.presentScene(scene)
            scene.didMove(to: view)
            scene.setReduceMotion(true)
            scene.debugSetProgress(row: 3)
            #expect(abs((scene.camera?.position.y ?? 0) - scene.size.height / 2) < 0.01)
            scene.debugSetProgress(row: 4)
            let followed = scene.camera?.position.y ?? 0
            #expect(followed > scene.size.height / 2)
            scene.debugSetProgress(row: 3)
            #expect(scene.camera?.position.y == followed)
        }
    }

    @Test func tutorialPondAddsFiveAndTransitionDoesNotResetBreath() {
        let model = GameSessionModel(persistence: MemoryGamePersistence(), feedback: RecordingGameFeedback())
        model.startRun()
        guard let scene = model.scene else { Issue.record("Missing scene"); return }
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        for target in TutorialStep.movementTargets(center: model.config.columns / 2) {
            model.receive(.movementCompleted(target))
        }
        scene.debugSetProgress(row: 8)
        model.receive(.movementCompleted(scene.debugPlayerGridPosition))
        scene.update(1)
        for frame in 1...420 { scene.update(1 + Double(frame) / 60) }
        #expect(abs(scene.debugRemainingBreath - 3) < 0.05)
        scene.debugVisitPond(id: 0)
        #expect(model.phase == .playing)
        #expect(abs(scene.debugRemainingBreath - 8) < 0.05)
        scene.debugVisitPond(id: 0)
        #expect(abs(scene.debugRemainingBreath - 8) < 0.05)
    }
    @Test func largePondHasLargerVisualAndAddsTenOnlyOnce() throws {
        let world = WorldGenerator(config: .live).generate(seed: 42)
        let large = try #require(world.ponds.first { $0.kind == .large })
        let small = try #require(world.ponds.first { $0.kind == .small })
        let sink = RecordingGameSceneEventSink()
        let scene = GameScene(config: .live, seed: 42, eventSink: sink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        scene.setReduceMotion(true)
        scene.setGameplayRunning(true)
        scene.update(1)
        for frame in 1...420 { scene.update(1 + Double(frame) / 60) }
        #expect(abs(scene.debugRemainingBreath - 3) < 0.05)
        #expect(abs((scene.debugPondVisualScale(id: small.id) ?? 0) - 2.1) < 0.01)
        scene.debugSetProgress(row: large.position.row)
        #expect(abs((scene.debugPondVisualScale(id: large.id) ?? 0) - 2.8) < 0.01)
        scene.debugVisitPond(id: large.id)
        #expect(scene.debugRemainingBreath == 10)
        #expect(scene.debugPondIsDrained(id: large.id))
        scene.update(8.05)
        let remaining = scene.debugRemainingBreath
        scene.debugVisitPond(id: large.id)
        #expect(scene.debugRemainingBreath == remaining)
    }

}
