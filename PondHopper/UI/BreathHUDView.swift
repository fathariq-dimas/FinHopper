import SwiftUI

struct BreathHUDView: View {
    let remaining: Double
    let maximum: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var refillTick = 0
    @State private var previousRemaining = 0.0
    @State private var refillGlow = 0.0

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: warningLevel == .danger ? "exclamationmark.triangle.fill" : "drop.fill")
                    .foregroundStyle(barColor)
                    .accessibilityHidden(true)

                Text("BREATH")
                    .font(.caption.weight(.black))

                if let statusText {
                    Text(statusText)
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(barColor, in: Capsule())
                        .foregroundStyle(GamePalette.ink)
                }

                Spacer(minLength: 0)

                Text("\(clampedRemaining, format: .number.precision(.fractionLength(1)))s")
                    .font(.caption.monospacedDigit().weight(.black))
            }

            GeometryReader { proxy in
                let progressWidth = proxy.size.width * progress

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GamePalette.cream.opacity(0.2))

                    Capsule()
                        .fill(barColor)
                        .frame(width: progressWidth)

                    if differentiateWithoutColor, warningLevel != .none {
                        HStack(spacing: 8) {
                            ForEach(0..<18, id: \.self) { _ in
                                Capsule()
                                    .fill(GamePalette.ink.opacity(0.42))
                                    .frame(width: 3)
                            }
                        }
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: progressWidth)
                        }
                    }
                }
            }
            .frame(height: 16)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: progress)
            .overlay { Capsule().stroke(.cyan.opacity(refillGlow), lineWidth: 4) }
            .overlay {
                Capsule()
                    .stroke(GamePalette.cream.opacity(0.72), lineWidth: 2)
            }
        }
        .foregroundStyle(GamePalette.cream)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breath")
        .accessibilityValue(accessibilityValue)
        .onAppear { previousRemaining = remaining }
        .onChange(of: remaining) { new in
            if new > previousRemaining + 0.5 { refillTick += 1 }
            previousRemaining = new
        }
        .task(id: refillTick) {
            guard refillTick > 0 else { return }
            refillGlow = 1
            do { try await Task.sleep(for: .milliseconds(60)) } catch { return }
            withAnimation(.easeOut(duration: 0.4)) { refillGlow = 0 }
        }
    }

    private var clampedRemaining: Double {
        min(max(0, remaining), max(0, maximum))
    }

    private var progress: Double {
        guard maximum > 0 else { return 0 }
        return clampedRemaining / maximum
    }

    private var warningLevel: BreathWarningLevel {
        BreathWarningLevel.resolve(
            remaining: clampedRemaining,
            maximum: maximum,
            isActive: true
        )
    }

    private var statusText: String? {
        switch warningLevel {
        case .none:
            nil
        case .caution:
            "LOW"
        case .danger:
            "CRITICAL"
        }
    }

    private var barColor: Color {
        switch warningLevel {
        case .none:
            GamePalette.pond
        case .caution:
            GamePalette.caution
        case .danger:
            GamePalette.danger
        }
    }

    private var accessibilityValue: String {
        let seconds = Int(clampedRemaining.rounded())
        if let statusText {
            return "\(statusText), \(seconds) seconds remaining"
        }
        return "\(seconds) seconds remaining"
    }
}
