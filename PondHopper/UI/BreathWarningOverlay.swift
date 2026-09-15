import SwiftUI

struct BreathWarningOverlay: View {
    let remaining: Double
    let maximum: Double
    let isActive: Bool

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            BreathWarningEdgeView(
                color: warningColor,
                isLeadingEdge: true,
                isCritical: level == .danger,
                showsSymbol: differentiateWithoutColor
            )

            Spacer(minLength: 0)

            BreathWarningEdgeView(
                color: warningColor,
                isLeadingEdge: false,
                isCritical: level == .danger,
                showsSymbol: differentiateWithoutColor
            )
        }
        .opacity(level == .none ? 0 : 1)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.22), value: level)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var level: BreathWarningLevel {
        .resolve(remaining: remaining, maximum: maximum, isActive: isActive)
    }

    private var warningColor: Color {
        level == .danger ? GamePalette.danger : GamePalette.caution
    }
}
