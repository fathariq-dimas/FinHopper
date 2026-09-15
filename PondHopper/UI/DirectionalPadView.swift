import SwiftUI

struct DirectionalPadView: View {
    let isEnabled: Bool
    let onMove: (MoveDirection) -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 154, height: 154)
                .accessibilityHidden(true)

            DirectionalPadButton(
                direction: .up,
                systemImageName: "arrow.up",
                isEnabled: isEnabled,
                onMove: onMove
            )
            .offset(y: -50)

            DirectionalPadButton(
                direction: .down,
                systemImageName: "arrow.down",
                isEnabled: isEnabled,
                onMove: onMove
            )
            .offset(y: 50)

            DirectionalPadButton(
                direction: .left,
                systemImageName: "arrow.left",
                isEnabled: isEnabled,
                onMove: onMove
            )
            .offset(x: -50)

            DirectionalPadButton(
                direction: .right,
                systemImageName: "arrow.right",
                isEnabled: isEnabled,
                onMove: onMove
            )
            .offset(x: 50)
        }
        .frame(width: 164, height: 164)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Directional controls")
    }
}
