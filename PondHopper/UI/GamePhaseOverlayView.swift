import SwiftUI

struct GamePhaseOverlayView: View {
    @ObservedObject var model: GameSessionModel
    let onSettings: () -> Void

    var body: some View {
        switch model.phase {
        case .tutorial:
            TutorialOverlayView(model: model)
        case .menu:
            WaitingGameOverlayView(
                onStart: model.startRun,
                onSettings: onSettings
            )
        case .countdown(let value):
            Text("\(value)")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .frame(width: 112, height: 112)
                .foregroundStyle(GamePalette.cream)
                .background(GamePalette.ink.opacity(0.94), in: Circle())
                .overlay {
                    Circle()
                        .stroke(GamePalette.cream, lineWidth: 4)
                }
                .accessibilityLabel("Starting in \(value)")
                .accessibilityIdentifier("game.countdown")
        case .paused:
            GamePauseOverlayView(onResume: model.resume, onRetry: model.restart)
        case .gameOver(let reason):
            GameOverOverlayView(
                reason: reason,
                score: model.snapshot.score,
                bestScore: model.snapshot.bestScore,
                onPlay: model.returnToWaiting
            )
        case .playing:
            EmptyView()
        }
    }
}


struct GamePauseOverlayView: View {
    let onResume: () -> Void
    var onRetry: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Button(action: onResume) {
                Color.black.opacity(0.62)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 54, weight: .black))
                            Text("TAP TO RESUME")
                                .font(.headline.weight(.black))
                        }
                        .foregroundStyle(GamePalette.ink)
                        .frame(width: 210, height: 150)
                        .gamePanel(fill: GamePalette.cream, stroke: GamePalette.ink, cornerRadius: 26)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Resume game")
            .accessibilityIdentifier("pause.resume")

            if let onRetry {
                VStack {
                    Spacer()
                    Button("Retry", systemImage: "arrow.clockwise", action: onRetry)
                        .buttonStyle(PrimaryGameButtonStyle())
                        .accessibilityIdentifier("pause.retry")
                        .padding(.bottom, 32)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
