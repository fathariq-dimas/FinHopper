import UIKit

@MainActor
final class UIKitGameHapticService: GameHapticProviding {
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let blockedImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        lightImpact.prepare()
        blockedImpact.prepare()
        notification.prepare()
    }

    func play(_ kind: GameHapticKind) {
        switch kind {
        case .lightImpact:
            lightImpact.impactOccurred(intensity: 0.65)
            lightImpact.prepare()
        case .blockedImpact:
            blockedImpact.impactOccurred(intensity: 0.85)
            blockedImpact.prepare()
        case .success:
            notification.notificationOccurred(.success)
            notification.prepare()
        case .warning:
            notification.notificationOccurred(.warning)
            notification.prepare()
        case .error:
            notification.notificationOccurred(.error)
            notification.prepare()
        }
    }
}
