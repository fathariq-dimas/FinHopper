import SwiftUI

struct WaitingGameOverlayView: View {
    let onStart: (MoveDirection) -> Void
    let onSettings: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHintAnimating = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(waitingStartGesture)
                    .accessibilityHidden(true)

                title
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 78)
                    .allowsHitTesting(false)

                startHint
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 42)
                    .padding(.bottom, 54)

                Button("Settings", systemImage: "gearshape.fill", action: onSettings)
                    .labelStyle(.iconOnly)
                    .buttonStyle(GameIconButtonStyle(diameter: 52))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 12)
                    .padding(.trailing, 20)
                    .accessibilityIdentifier("mainMenu.settings")
            }
        }
    }

    private var title: some View {
        GameTitleView(fontSize: 58)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Fin Hopper")
    }

    private var startHint: some View {
        HStack(spacing: 13) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(GamePalette.pond)
                .frame(width: 38)

            Text("TAP OR SWIPE")
                .font(.headline.weight(.black))
        }
        .foregroundStyle(GamePalette.ink)
        .padding(.horizontal, 18)
        .frame(minHeight: 72)
        .gamePanel(
            fill: GamePalette.cream.opacity(0.96),
            stroke: GamePalette.ink,
            cornerRadius: 22
        )
        .scaleEffect(isHintAnimating ? 0.97 : 1)
        .offset(y: isHintAnimating ? 3 : 0)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            onStart(.up)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tap or swipe anywhere to play")
        .accessibilityHint("A tap moves up. A swipe starts by moving in that direction.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            onStart(.up)
        }
        .accessibilityIdentifier("mainMenu.play")
        .onAppear(perform: animateHint)
    }

    private var waitingStartGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { value in
                onStart(direction(for: value.translation))
            }
    }

    private func direction(for translation: CGSize) -> MoveDirection {
        let horizontalDistance = Double(translation.width)
        let verticalDistance = Double(-translation.height)
        let swipeThreshold = 24.0

        if hypot(horizontalDistance, verticalDistance) < swipeThreshold {
            return .up
        }
        if abs(horizontalDistance) > abs(verticalDistance) {
            return horizontalDistance > 0 ? .right : .left
        }
        return verticalDistance > 0 ? .up : .down
    }

    private func animateHint() {
        isHintAnimating = false
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            isHintAnimating = true
        }
    }
}
