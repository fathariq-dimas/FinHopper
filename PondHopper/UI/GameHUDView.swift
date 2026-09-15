import SwiftUI

struct GameHUDView: View {
    static let panelCornerRadius: CGFloat = 22
    let snapshot: GameSnapshot
    let maximumBreath: Double
    let canPause: Bool
    let onPause: () -> Void
    var showsBreath = true
    var showsScore = true

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if showsScore { ScoreHUDView(score: snapshot.score) }
                Spacer(minLength: 8)
                PauseGameButton(isEnabled: canPause, action: onPause)
            }

            if showsBreath { BreathHUDView(
                remaining: snapshot.breathRemaining,
                maximum: maximumBreath
            ) }
        }
        .padding(12)
        .gamePanel(
            fill: GamePalette.ink.opacity(0.94),
            stroke: GamePalette.cream.opacity(0.9),
            cornerRadius: Self.panelCornerRadius
        )
    }
}
