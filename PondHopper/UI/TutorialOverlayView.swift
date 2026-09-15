import SwiftUI

struct TutorialOverlayView: View {
    @ObservedObject var model: GameSessionModel

    var body: some View {
        ZStack {
            if let reason = model.tutorialFailure {
                failureOverlay(reason)
            } else if model.tutorialPaused {
                GamePauseOverlayView(onResume: model.resume)
            } else {
                Color.clear
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(model.tutorialStep.instruction)
                    .accessibilityIdentifier("tutorial.gesture")
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func failureOverlay(_ reason: GameOverReason) -> some View {
        ZStack {
            GamePalette.ink.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: reason == .vehicleCollision ? "exclamationmark.triangle.fill" : "drop.triangle.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(GamePalette.warning)
                Text(reason == .vehicleCollision ? "You got hit!" : "Out of breath!")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("tutorial.failure")
                Text(reason == .vehicleCollision ? "Watch where you land." : "Reach the pond for +5 seconds.")
                    .font(.headline)
                Button("Try Again", systemImage: "arrow.clockwise", action: model.continueTutorial)
                    .buttonStyle(PrimaryGameButtonStyle())
                    .accessibilityIdentifier("tutorial.retry")
            }
            .foregroundStyle(GamePalette.ink)
            .padding(24)
            .frame(maxWidth: 330)
            .gamePanel(fill: GamePalette.cream, stroke: GamePalette.ink, cornerRadius: 28)
            .padding(.horizontal, 24)
        }
    }
}
