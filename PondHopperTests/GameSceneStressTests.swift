import SpriteKit
import Testing
@testable import FinHopper

@MainActor
struct GameSceneStressTests {
    @Test
    func fiveMinuteMaximumTierSimulationKeepsNodeCountsBounded() {
        let eventSink = RecordingGameSceneEventSink()
        let scene = GameScene(config: .live, seed: 8_675_309, eventSink: eventSink)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.presentScene(scene)
        scene.didMove(to: view)
        scene.debugSetProgress(row: 140)

        var maximumRenderedRows = 0
        var maximumVehicles = 0
        var maximumWorldChildren = 0

        for frame in 0...(5 * 60 * 60) {
            scene.debugSetSimulationElapsed(Double(frame) / 60)
            let diagnostics = scene.debugDiagnostics
            maximumRenderedRows = max(maximumRenderedRows, diagnostics.renderedRowCount)
            maximumVehicles = max(maximumVehicles, diagnostics.vehicleNodeCount)
            maximumWorldChildren = max(maximumWorldChildren, diagnostics.worldChildCount)
        }

        let tileSize = Double(view.frame.width) / Double(GameConfig.live.columns)
        let rowsPerScreen = Int(ceil(Double(view.frame.height) / tileSize))
        let maximumRowsForStreamingWindow = (rowsPerScreen * 3) + 7

        #expect(GameConfig.live.difficulty(for: 140).tier == 6)
        #expect(maximumRenderedRows <= maximumRowsForStreamingWindow)
        #expect(maximumVehicles <= 128)
        #expect(maximumWorldChildren <= 200)

        view.presentScene(nil)
    }
}
