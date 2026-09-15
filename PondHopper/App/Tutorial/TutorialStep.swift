import Foundation

nonisolated enum TutorialStep: Equatable, Sendable {
    case movement(Int)
    case traffic
    case pond

    static let movementDirections: [MoveDirection] = [.up, .left, .down, .right, .right, .up, .up, .up]

    static func movementTargets(center: Int) -> [GridPosition] {
        var position = GridPosition(column: center, row: 2)
        return movementDirections.map { direction in
            position = position.moved(direction)
            return position
        }
    }

    var gestureAsset: String {
        if self == .movement(0) { return "tutorial-hand-click" }
        switch expectedDirection {
        case .left: return "tutorial-swipe-left"
        case .right: return "tutorial-swipe-right"
        case .down: return "tutorial-swipe-down"
        default: return "tutorial-swipe-up"
        }
    }

    var expectedDirection: MoveDirection? {
        if case .movement(let index) = self { return Self.movementDirections[index] }
        return nil
    }

    // Spoken guidance remains available without a visible instruction card.
    var instruction: String {
        switch self {
        case .movement(0): return "Tap to hop forward."
        case .movement:
            switch expectedDirection {
            case .left: return "Swipe left."
            case .right: return "Swipe right."
            case .down: return "Swipe down."
            default: return "Swipe up."
            }
        case .traffic: return "Avoid trees and cars. Land in a clear space."
        case .pond: return "Your breath is running out. Reach the glowing pond for five extra seconds."
        }
    }

}
