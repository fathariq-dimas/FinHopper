import SpriteKit

@MainActor
final class FishTrailMarkNode: SKNode {
    let gridPosition: GridPosition
    private(set) var age = 0.0
    static let lifetime = 1.6

    private static let imprintTexture: SKTexture = {
        let texture = SKTexture(imageNamed: "wet-fish-trail")
        texture.filteringMode = .linear
        return texture
    }()

    init(position: GridPosition, orientation: FishSpriteOrientation, tileSize: Double) {
        gridPosition = position
        super.init()

        // Match the side that touched the ground before the fish flipped into its hop.
        let imprint = SKSpriteNode(texture: Self.imprintTexture)
        imprint.size = CGSize(width: tileSize * 1.50, height: tileSize * 1.50)
        addChild(imprint)
        xScale = orientation.horizontalScale
        yScale = orientation.verticalScale
        zPosition = 3
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("FishTrailMarkNode requires a grid position and orientation.")
    }

    func advance(by deltaTime: Double, distanceFromFish: Int) {
        age += max(0, deltaTime)
        let timeOpacity = max(0, 1 - age / Self.lifetime)
        let distanceOpacity = 0.65 / Double(max(1, distanceFromFish))
        alpha = timeOpacity * distanceOpacity
    }
}
