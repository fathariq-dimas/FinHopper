import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct GameScenePauseTests {
    @Test
    func pauseSurvivesSpriteKitClearingItsOwnPauseFlag() {
        let scene = makePresentedScene()

        scene.setGameplayRunning(true)
        #expect(scene.debugIsAcceptingGameplayInput)

        scene.setSimulationPaused(true)
        #expect(scene.debugIsSimulationPaused)
        #expect(!scene.debugIsAcceptingGameplayInput)

        // SpriteKit clears `isPaused` when the app foregrounds or the hosting
        // SpriteView rebuilds its SKView. The pause must still hold.
        scene.debugSimulateExternalUnpause()
        #expect(!scene.isPaused)

        scene.update(1)
        scene.update(2)

        #expect(scene.debugIsSimulationPaused)
        #expect(scene.isPaused)
        #expect(!scene.debugIsAcceptingGameplayInput)
    }

    @Test
    func pausedRunDoesNotAdvanceBreathEvenAfterExternalUnpause() {
        let eventSink = RecordingGameSceneEventSink()
        let scene = makePresentedScene(eventSink: eventSink)

        scene.setGameplayRunning(true)
        scene.update(1)
        scene.update(1.5)

        scene.setSimulationPaused(true)
        scene.debugSimulateExternalUnpause()
        eventSink.reset()

        // Pump well past the breath budget.
        for frame in 1...400 {
            scene.update(2 + Double(frame) * 0.05)
        }

        #expect(!eventSink.events.contains(where: isBreathChange))
        #expect(!eventSink.events.contains(where: isGameOver))
    }

    @Test
    func pausedRunRejectsMovementInput() {
        let eventSink = RecordingGameSceneEventSink()
        let scene = makePresentedScene(eventSink: eventSink)

        scene.setGameplayRunning(true)
        scene.setSimulationPaused(true)
        scene.debugSimulateExternalUnpause()
        eventSink.reset()

        let startPosition = scene.debugPlayerGridPosition
        scene.enqueueMovement(.up)
        scene.enqueueGesture(horizontalDistance: 0, verticalDistance: 200)

        #expect(scene.debugPlayerGridPosition == startPosition)
        #expect(!eventSink.events.contains(.feedback(.hop)))
        #expect(!eventSink.events.contains(.feedback(.blockedMove)))
    }

    @Test
    func resumingFromPauseDoesNotStartGameplayOnItsOwn() {
        let scene = makePresentedScene()

        // The waiting/menu world animates but is not a live run.
        scene.setGameplayRunning(false)
        scene.setSimulationPaused(true)
        scene.setSimulationPaused(false)

        #expect(!scene.debugIsSimulationPaused)
        #expect(!scene.debugIsAcceptingGameplayInput)
    }

    @Test
    func gameplayResumesNormallyAfterPause() {
        let scene = makePresentedScene()

        scene.setGameplayRunning(true)
        scene.setSimulationPaused(true)
        scene.setGameplayRunning(true)

        #expect(!scene.debugIsSimulationPaused)
        #expect(!scene.isPaused)
        #expect(scene.debugIsAcceptingGameplayInput)
    }

    private func makePresentedScene(
        eventSink: RecordingGameSceneEventSink = RecordingGameSceneEventSink()
    ) -> GameScene {
        let scene = GameScene(config: .live, seed: 42, eventSink: eventSink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        return scene
    }

    private func isBreathChange(_ event: GameEvent) -> Bool {
        if case .breathChanged = event { return true }
        return false
    }

    private func isGameOver(_ event: GameEvent) -> Bool {
        if case .gameOver = event { return true }
        return false
    }
}
