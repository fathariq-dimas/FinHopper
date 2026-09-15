import SwiftUI

struct RootGameView: View {
    @ObservedObject var model: GameSessionModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsSettings = false

    var body: some View {
        GameView(
            model: model,
            onSettings: { showsSettings = true }
        )
        .sheet(isPresented: $showsSettings) {
            SettingsView(
                settings: $model.settings,
                onDone: { showsSettings = false }
            )
        }
        // `onChange` runs synchronously with the phase transition. A `.task(id:)`
        // would defer the pause and can be cancelled while the app is being
        // backgrounded, which is exactly when the pause must land.
        .onChange(of: scenePhase) { newPhase in
            model.handleScenePhase(newPhase)
        }
    }
}
