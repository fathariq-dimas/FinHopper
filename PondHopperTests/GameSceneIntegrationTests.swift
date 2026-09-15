import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct GameSceneIntegrationTests {
    @Test func expansionKeepsInputLiveAndDoesNotReplaceSceneState() async {
        let sink = RecordingGameSceneEventSink()
        let scene = GameScene(config: .live, seed: 42, eventSink: sink)
        let initialRows = scene.debugDiagnostics.blueprintRowCount
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        scene.setGameplayRunning(true)
        scene.enqueueMovement(.up)
        #expect(sink.events.contains(.feedback(.hop)))
        #expect(scene.debugIsHopProtected)
        #expect(scene.debugDiagnostics.blueprintRowCount == initialRows)
        await scene.debugWaitForExpansion()
        #expect(scene.debugDiagnostics.blueprintRowCount > initialRows)
        #expect(!scene.debugIsSimulationPaused)
        view.presentScene(nil)
    }

    @Test
    func nearbyTrafficSoundsDuringGameplayButNotInMenuOrPause() throws {
        let sink = RecordingGameSceneEventSink()
        let scene = GameScene(config: .live, seed: 42, eventSink: sink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        let roadRow = try #require(scene.debugFirstRoadRow)
        scene.debugSetProgress(row: roadRow - 1)
        scene.setGameplayRunning(false)
        scene.update(1)
        for frame in 1...120 { scene.update(1 + Double(frame) / 60) }
        #expect(!sink.events.contains(.feedback(.vehiclePass)))

        scene.setGameplayRunning(true)
        scene.update(4)
        for frame in 1...180 { scene.update(4 + Double(frame) / 60) }
        let passCount = sink.events.filter { $0 == .feedback(.vehiclePass) }.count
        #expect(passCount > 0)
        #expect(passCount <= 3)
        scene.setSimulationPaused(true)
        sink.reset()
        for frame in 1...120 { scene.update(8 + Double(frame) / 60) }
        #expect(!sink.events.contains(.feedback(.vehiclePass)))
        view.presentScene(nil)
    }

    @Test
    func shortBreathConfigurationStillAcceptsMovement() async throws {
        let config = GameConfig.live.replacingMaximumBreath(with: 2)
        let eventSink = RecordingGameSceneEventSink()
        let scene = GameScene(config: config, seed: 42, eventSink: eventSink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)

        scene.setGameplayRunning(true)
        let destination = scene.debugPlayerGridPosition.moved(.up)
        scene.enqueueMovement(.up)

        #expect(eventSink.events.contains(.feedback(.hop)))

        for _ in 0..<40 where scene.debugPlayerGridPosition != destination {
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(scene.debugPlayerGridPosition == destination)

        view.presentScene(nil)
    }
}
