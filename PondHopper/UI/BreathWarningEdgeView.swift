import SwiftUI

struct BreathWarningEdgeView: View {
    let color: Color
    let isLeadingEdge: Bool
    let isCritical: Bool
    let showsSymbol: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            if showsSymbol {
                Image(systemName: isCritical ? "exclamationmark.triangle.fill" : "exclamationmark")
                    .font(.headline)
                    .foregroundStyle(isCritical ? GamePalette.cream : GamePalette.ink)
            }
        }
        .frame(width: 28)
        .accessibilityHidden(true)
    }

    private var gradientColors: [Color] {
        if isLeadingEdge {
            [color.opacity(0.88), color.opacity(0)]
        } else {
            [color.opacity(0), color.opacity(0.88)]
        }
    }
}
