import SwiftUI

struct ScoreHUDView: View {
    let score: Int
    @State private var milestoneScale = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .foregroundStyle(GamePalette.caution)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: -2) {
                Text("SCORE")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(GamePalette.cream.opacity(0.76))
                Text("\(score)")
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(GamePalette.cream)
                    .scaleEffect(reduceMotion ? 1 : milestoneScale)
                    .task(id: score / 10) {
                        guard score >= 10, !reduceMotion else { return }
                        withAnimation(.easeOut(duration: 0.10)) { milestoneScale = 1.22 }
                        do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
                        withAnimation(.easeOut(duration: 0.16)) { milestoneScale = 1 }
                    }
            }
        }
        .frame(minHeight: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Score \(score)")
            .accessibilityIdentifier("game.score")
    }
}
