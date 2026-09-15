import SpriteKit

@MainActor
enum GardenDecoration {
    static let textures: [SKTexture] = {
        let sheet = SKTexture(imageNamed: "garden-decorations")
        return (0..<16).map { index in
            let texture = SKTexture(rect: CGRect(
                x: Double(index % 4) / 4, y: Double(3 - index / 4) / 4,
                width: 0.25, height: 0.25
            ), in: sheet)
            texture.filteringMode = .linear
            return texture
        }
    }()

    static func variant(row: Int, column: Int) -> Int? {
        let value = placementHash(row: row, column: column)
        guard value % 100 < 22 else { return nil }
        return Int((value >> 16) % 16)
    }

    static func offset(row: Int, column: Int) -> CGPoint {
        let value = placementHash(row: row, column: column)
        return CGPoint(x: Double((value >> 32) % 101) / 100 * 0.36 - 0.18,
            y: Double((value >> 48) % 101) / 100 * 0.28 - 0.14)
    }

    // Stable mixing avoids repeating diagonal patterns and keeps placement fixed on redraw.
    private static func placementHash(row: Int, column: Int) -> UInt64 {
        var value = UInt64(bitPattern: Int64(row)) &* 0x9E3779B97F4A7C15
        value ^= UInt64(bitPattern: Int64(column)) &* 0xBF58476D1CE4E5B9
        value &+= 0x94D049BB133111EB
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    static func scale(for variant: Int) -> Double {
        (4..<8).contains(variant) ? 0.78 : 0.55
    }
}
