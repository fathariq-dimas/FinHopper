import SwiftUI

struct GamePanelModifier: ViewModifier {
    let fill: Color
    let stroke: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 3)
            }
    }
}

extension View {
    func gamePanel(
        fill: Color,
        stroke: Color,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(GamePanelModifier(
            fill: fill,
            stroke: stroke,
            cornerRadius: cornerRadius
        ))    }
}
