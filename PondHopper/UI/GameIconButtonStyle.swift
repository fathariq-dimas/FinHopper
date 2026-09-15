import SwiftUI

struct GameIconButtonStyle: ButtonStyle {
    var diameter: CGFloat = 50
    var fill = GamePalette.cream
    var foreground = GamePalette.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(foreground)
            .frame(width: diameter, height: diameter)
            .background(configuration.isPressed ? GamePalette.caution : fill, in: Circle())
            .overlay {
                Circle()
                    .stroke(GamePalette.ink, lineWidth: 3)
            }
            .offset(y: configuration.isPressed ? 3 : 0)
            .contentShape(Circle())
    }
}
