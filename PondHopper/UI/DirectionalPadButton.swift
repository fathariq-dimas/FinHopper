
import SwiftUI

struct DirectionalPadButton: View {
    let direction: MoveDirection
    let systemImageName: String
    let isEnabled: Bool
    let onMove: (MoveDirection) -> Void

    var body: some View {
        Button(direction.accessibilityName, systemImage: systemImageName, action: sendDirection)
            .labelStyle(.iconOnly)
            .font(.headline)
            .foregroundStyle(GamePalette.ink)
            .frame(width: 48, height: 48)
            .background(GamePalette.cream, in: .circle)
            .disabled(!isEnabled)
            .accessibilityIdentifier("dpad.\(direction.accessibilityName.lowercased())")
    }

    private func sendDirection() {
        onMove(direction)
    }
}
