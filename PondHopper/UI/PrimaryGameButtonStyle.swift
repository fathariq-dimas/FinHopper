import SwiftUI

struct PrimaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(
                configuration.isPressed ? GamePalette.caution : GamePalette.pond,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(GamePalette.ink, lineWidth: 3)
            }
            .offset(y: configuration.isPressed ? 3 : 0)
    }
}
