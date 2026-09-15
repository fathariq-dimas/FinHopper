import SwiftUI

/// Two-line FIN / HOPPER title used on the waiting and loading screens.
/// "FIN" renders in cream with a black stroke; "HOPPER" renders in ink
/// (dark) with a white stroke.
struct GameTitleView: View {
    var fontSize: CGFloat = 58

    var body: some View {
        VStack(spacing: -8) {
            strokedText("FIN", fill: GamePalette.cream, stroke: .black)
            strokedText("HOPPER", fill: GamePalette.ink, stroke: .white)
        }
        .font(.system(size: fontSize, weight: .black, design: .rounded))
        .multilineTextAlignment(.center)
    }

    // Simulates a text stroke by drawing the same text four times in the
    // stroke colour (shifted one pixel in each cardinal direction) and then
    // drawing the fill-coloured text on top.
    private func strokedText(_ string: String, fill: Color, stroke: Color) -> some View {
        let offset: CGFloat = max(1.5, fontSize * 0.028)
        return ZStack {
            // Outline layer — four shifted copies
            Text(string)
                .foregroundStyle(stroke)
                .offset(x: -offset, y: 0)
            Text(string)
                .foregroundStyle(stroke)
                .offset(x: offset, y: 0)
            Text(string)
                .foregroundStyle(stroke)
                .offset(x: 0, y: -offset)
            Text(string)
                .foregroundStyle(stroke)
                .offset(x: 0, y: offset)
            // Fill layer on top
            Text(string)
                .foregroundStyle(fill)
        }
    }
}
