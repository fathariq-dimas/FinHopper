import SpriteKit
import SwiftUI

struct GameLoadingView: View {

    private static let gardenImages = GardenDecoration.textures.map { Image(decorative: $0.cgImage(), scale: 1) }

    private static let sceneryImages: [String: CGImage] = Dictionary(
        uniqueKeysWithValues: ["pond-idle-0", "tree", "fish-flop-1", "car-orange", "truck-blue"].map {
            ($0, SKTexture(imageNamed: $0).cgImage())
        }
    )

    private func sceneryImage(_ name: String) -> Image {
        Image(decorative: Self.sceneryImages[name]!, scale: 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.34, green: 0.78, blue: 0.31)
                    .ignoresSafeArea()

                parkDetails(in: proxy.size)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                GameTitleView(fontSize: 58)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 78)

                loadingCard
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 42)
                    .padding(.bottom, 54)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fin Hopper is preparing the park")
    }

    private func parkDetails(in size: CGSize) -> some View {
        ZStack {
            Canvas { context, canvasSize in
                let tileSize = canvasSize.width / 7
                guard tileSize > 0 else { return }
                for row in 0..<Int(ceil(canvasSize.height / tileSize)) {
                    let rect = CGRect(x: 0, y: CGFloat(row) * tileSize, width: canvasSize.width, height: tileSize)
                    context.fill(Path(rect), with: .color(row.isMultiple(of: 2)
                        ? Color(red: 0.34, green: 0.78, blue: 0.31)
                        : Color(red: 0.30, green: 0.72, blue: 0.27)))
                    // Leave the road and focal pond/fish area clear.
                    guard !(0.54...0.76).contains(CGFloat(row) * tileSize / canvasSize.height) else { continue }
                    for column in 0..<7 {
                        guard let variant = GardenDecoration.variant(row: row, column: column) else { continue }
                        let offset = GardenDecoration.offset(row: row, column: column)
                        let center = CGPoint(x: (CGFloat(column) + 0.5 + offset.x) * tileSize,
                            y: (CGFloat(row) + 0.5 + offset.y) * tileSize)
                        if (0.34...0.49).contains(center.y / canvasSize.height), (1...5).contains(column) { continue }
                        let extent = tileSize * GardenDecoration.scale(for: variant)
                        context.draw(Self.gardenImages[variant], in: CGRect(
                            x: center.x - extent / 2, y: center.y - extent / 2,
                            width: extent, height: extent))
                    }
                }
            }

            sceneryImage("pond-idle-0")
                .resizable()
                // Match GameScene: 2.1 tiles wide, with rows 1.2 times taller.
                .frame(
                    width: size.width / CGFloat(GameConfig.live.columns) * 2.1,
                    height: size.width / CGFloat(GameConfig.live.columns) * 1.2 * 2.1
                )
                .position(x: size.width * 0.65, y: size.height * 0.43)

            sceneryImage("tree")
                .resizable()
                .scaledToFit()
                .frame(width: size.width * 0.26, height: size.width * 0.30)
                .position(x: size.width * 0.13, y: size.height * 0.30)

            sceneryImage("tree")
                .resizable()
                .scaledToFit()
                .frame(width: size.width * 0.25, height: size.width * 0.30)
                .position(x: size.width * 0.89, y: size.height * 0.515)

            loadingRoad(width: size.width)
                .position(x: size.width / 2, y: size.height * 0.65)

            sceneryImage("fish-flop-1")
                .resizable()
                .scaledToFit()
                .frame(width: size.width * 0.23, height: size.width * 0.23)
                .position(x: size.width * 0.30, y: size.height * 0.43)
        }
        .accessibilityHidden(true)
    }

    private func loadingRoad(width: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(red: 0.35, green: 0.40, blue: 0.45))
                .frame(width: width * 1.2, height: 126)

            HStack(spacing: 18) {
                ForEach(0..<9, id: \.self) { _ in
                    Capsule()
                        .fill(Color(red: 1, green: 0.94, blue: 0.76))
                        .frame(width: 28, height: 5)
                }
            }

            sceneryImage("car-orange")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.36, height: width * 0.36)
                .offset(x: -width * 0.24, y: -31)

            sceneryImage("truck-blue")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.46, height: width * 0.46)
                .scaleEffect(x: -1, y: 1)
                .offset(x: width * 0.25, y: 31)
        }
        .frame(width: width, height: 126)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.04, green: 0.25, blue: 0.30))
                .frame(height: 6)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(red: 0.04, green: 0.25, blue: 0.30))
                .frame(height: 6)
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(GamePalette.pond)
                .scaleEffect(1.1)

            VStack(alignment: .leading, spacing: 1) {
                Text("GETTING THE FIN READY")
                    .font(.caption.weight(.black))
                Text("Preparing the park…")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(GamePalette.deepGrass)
            }
        }
        .foregroundStyle(GamePalette.ink)
        .padding(.horizontal, 18)
        .frame(maxWidth: 310, minHeight: 70)
        .gamePanel(
            fill: GamePalette.cream.opacity(0.97),
            stroke: GamePalette.ink,
            cornerRadius: 22
        )
    }


}


#Preview {
    GameLoadingView()
}
