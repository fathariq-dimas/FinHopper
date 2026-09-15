import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct TutorialTests {
    @Test func instructionTransitionPreservesTouchAndFrameClock() throws {
        let model = GameSessionModel(persistence: MemoryGamePersistence(),
            feedback: RecordingGameFeedback())
        model.startRun()
        let scene = try #require(model.scene)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        scene.update(1)
        scene.debugBeginPendingTouch()
        model.receive(.movementCompleted(TutorialStep.movementTargets(center: model.config.columns / 2)[0]))
        #expect(model.tutorialStep == .movement(1))
        #expect(scene.debugHasPendingTouch)
        #expect(scene.debugFrameTime == 1)
        model.pause()
        #expect(!scene.debugHasPendingTouch)
        #expect(scene.debugFrameTime == 0)
    }

    @Test func tutorialPreparesOnlyNearbyWorldAndCanExpand() async {
        let scene = GameScene(config: .live, seed: 42,
            eventSink: RecordingGameSceneEventSink(), tutorialSection: 1)
        let initialRows = scene.debugDiagnostics.blueprintRowCount
        #expect(initialRows < 110)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        // Only the tutorial road intersects the camera; future roads stay dormant.
        #expect(scene.debugDiagnostics.vehicleNodeCount < 5)
        scene.debugSetProgress(row: initialRows - 20)
        await scene.debugWaitForExpansion()
        #expect(scene.debugDiagnostics.blueprintRowCount > initialRows)
    }

    @Test func waitingAndGameplayShareSceneAndRetrySkipsTutorial() {
        let persistence = MemoryGamePersistence()
        persistence.hasSeenTutorial = true
        persistence.bestScore = 25
        let model = GameSessionModel(persistence: persistence,
            launchOptions: GameLaunchOptions(arguments: ["--finhopper-skip-tutorial"]), feedback: RecordingGameFeedback())
        let scene = model.scene
        model.startRun()
        #expect(model.phase == .tutorial)
        #expect(model.scene === scene)
        model.receive(.scoreChanged(100))
        #expect(model.snapshot.score == 0)
        completeTutorial(model)
        #expect(model.phase == .playing)
        #expect(model.scene === scene)
        #expect(model.snapshot.score == 0)
        #expect(model.snapshot.breathRemaining == model.config.maximumBreath)
        model.receive(.gameOver(.vehicleCollision))
        model.restart()
        #expect(model.phase == .playing)
        #expect(model.scene !== scene)
        #expect(persistence.bestScore == 25)
        let relaunched = GameSessionModel(persistence: persistence, feedback: RecordingGameFeedback())
        relaunched.startRun()
        #expect(relaunched.phase == .tutorial)
    }

    @Test func failuresReturnToCheckpointWithoutChangingScene() throws {
        let model = GameSessionModel(persistence: MemoryGamePersistence(), feedback: RecordingGameFeedback())
        model.startRun()
        let scene = try #require(model.scene)
        let center = model.config.columns / 2
        for target in TutorialStep.movementTargets(center: center) {
            model.receive(.movementCompleted(target))
        }
        #expect(model.tutorialStep == .traffic)
        model.receive(.gameOver(.vehicleCollision))
        #expect(model.scene === scene)
        #expect(model.tutorialFailure == .vehicleCollision)
        #expect(!model.tutorialCanMove)
        #expect(scene.debugIsSimulationPaused)
        let collidedPosition = scene.debugPlayerGridPosition
        model.move(.up)
        #expect(scene.debugPlayerGridPosition == collidedPosition)
        model.continueTutorial()
        #expect(model.tutorialFailure == nil)
        #expect(scene.debugPlayerGridPosition == .init(column: center + 1, row: 5))
        #expect(model.tutorialCanMove)
        model.receive(.movementCompleted(.init(column: center - 1, row: 8)))
        #expect(model.tutorialStep == .pond)
        model.receive(.gameOver(.outOfBreath))
        #expect(model.tutorialFailure == .outOfBreath)
        #expect(!model.tutorialCanMove)
        model.continueTutorial()
        #expect(scene.debugPlayerGridPosition == .init(column: center + 1, row: 8))
        #expect(model.snapshot.breathRemaining == model.config.maximumBreath)
        model.handleScenePhase(.background)
        #expect(scene.debugIsSimulationPaused)
        model.handleScenePhase(.active)
        #expect(!model.tutorialCanMove)
        model.continueTutorial()
        #expect(model.tutorialCanMove)
    }

    @Test func actualArrivalTransitionsToGameplayWithZeroScore() throws {
        let model = GameSessionModel(persistence: MemoryGamePersistence(), feedback: RecordingGameFeedback())
        model.startRun()
        let scene = try #require(model.scene)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        model.setReduceMotion(true)
        let start = scene.debugPlayerGridPosition
        model.move(.left)
        #expect(scene.debugPlayerGridPosition == start)
        for direction in TutorialStep.movementDirections {
            model.move(direction)
            scene.debugFinishActiveMovement()
        }
        #expect(model.tutorialStep == .traffic)
        #expect(model.scene === scene)
        scene.debugSetProgress(row: 8)
        model.receive(.movementCompleted(scene.debugPlayerGridPosition))
        #expect(model.tutorialStep == .pond)
        #expect(!scene.debugPondIsDrained(id: 0))
        scene.debugSetProgress(row: TutorialWorld.pondRow)
        model.move(.up)
        scene.debugFinishActiveMovement()
        #expect(scene.debugPlayerGridPosition.row == TutorialWorld.pondRow)
        #expect(model.phase == .tutorial)
        scene.debugVisitPond(id: 0)
        #expect(model.phase == .playing)
        #expect(model.scene === scene)
        #expect(model.snapshot.score == 0)
        #expect(scene.debugPondIsDrained(id: 0))
        scene.debugSetProgress(row: TutorialWorld.pondRow)
        model.move(.up)
        scene.debugFinishActiveMovement()
        #expect(model.snapshot.score == 1)
    }

    @Test func prefixJoinsOriginalStartingPondAndPreservesGeneratedWorld() {
        let normal = WorldGenerator(config: .live).generate(seed: 42)
        let world = TutorialWorld.prepend(to: normal, columns: GameConfig.live.columns)
        #expect(world.ponds.first?.position.row == TutorialWorld.pondRow)
        #expect(world.roadLanes[6]?.speedInScreenWidths == 0.20)
        #expect(world.rows.count == normal.rows.count + TutorialWorld.offset)
        #expect(world.ponds.count == normal.ponds.count)
        for pond in normal.ponds {
            #expect(world.pond(id: pond.id)?.position.row == pond.position.row + TutorialWorld.offset)
        }
    }
}
