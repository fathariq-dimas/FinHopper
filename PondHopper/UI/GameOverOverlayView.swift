import SwiftUI

struct GameOverOverlayView: View {
    let reason: GameOverReason
    let score: Int
    let bestScore: Int
    let onPlay: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        ZStack {
            GamePalette.ink.opacity(0.58)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: reason == .outOfBreath ? "drop.triangle.fill" : "car.side.fill")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(reason == .outOfBreath ? GamePalette.pond : GamePalette.warning)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text("GAME OVER")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .accessibilityIdentifier("gameOver.title")

                    Text(reason == .outOfBreath ? "Out of Breath" : "Watch the Traffic")
                        .font(.headline)
                        .foregroundStyle(GamePalette.deepGrass)
                }

                HStack(spacing: 10) {
                    resultTile(label: "SCORE", value: score, identifier: "gameOver.distance")
                    resultTile(label: "BEST", value: bestScore, identifier: "gameOver.bestScore")
                }

                Button("Play Again", systemImage: "play.fill", action: onPlay)
                    .buttonStyle(PrimaryGameButtonStyle())
                    .accessibilityIdentifier("gameOver.retry")
            }
            .foregroundStyle(GamePalette.ink)
            .padding(24)
            .frame(maxWidth: 330)
            .gamePanel(
                fill: GamePalette.cream,
                stroke: GamePalette.ink,
                cornerRadius: 28
            )
            .padding(.horizontal, 24)
        }
        .opacity(revealed ? 1 : 0)
        .allowsHitTesting(revealed)
        .task {
            if reason == .vehicleCollision && !reduceMotion {
                do { try await Task.sleep(for: .milliseconds(220)) } catch { return }
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { revealed = true }
        }
    }

    private func resultTile(label: String, value: Int, identifier: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(GamePalette.deepGrass)
            Text("\(value)")
                .font(.system(.title, design: .rounded, weight: .black))
                .monospacedDigit()
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(GamePalette.grass.opacity(0.22), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(GamePalette.deepGrass.opacity(0.45), lineWidth: 2)
        }
    }
}
