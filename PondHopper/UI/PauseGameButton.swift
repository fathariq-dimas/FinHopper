import SwiftUI

struct PauseGameButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button("Pause", systemImage: "pause.fill", action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(GameIconButtonStyle(diameter: 44))
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.55)
            .accessibilityIdentifier("game.pause")
    }
}
