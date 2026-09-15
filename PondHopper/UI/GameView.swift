import SpriteKit
import SwiftUI

struct GameView: View {
    @ObservedObject var model: GameSessionModel
    let onSettings: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        ZStack {
            if let scene = model.scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .id(ObjectIdentifier(scene))
                    .ignoresSafeArea()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Fin Hopper game field")
                    .accessibilityHint("Tap to move forward, or swipe to choose a direction.")
                    .accessibilityIdentifier("game.field")
            } else {
                GameLoadingView()
            }
        }
        .overlay {
            BreathWarningOverlay(
                remaining: model.snapshot.breathRemaining,
                maximum: model.config.maximumBreath,
                isActive: model.phase == .playing || (model.tutorialCanMove && model.tutorialStep == .pond)
            )
        }
        .overlay(alignment: .top) {
            if model.phase != .menu {
                VStack(spacing: 8) {
                    if model.phase == .tutorial && model.tutorialStep != .pond {
                        HStack {
                            Spacer()
                            PauseGameButton(isEnabled: true, action: model.pause)
                        }
                    } else {
                        GameHUDView(
                            snapshot: model.snapshot,
                            maximumBreath: model.config.maximumBreath,
                            canPause: model.phase == .playing || model.phase == .tutorial,
                            onPause: model.pause,
                            showsBreath: model.phase != .tutorial || model.tutorialStep == .pond,
                            showsScore: model.phase != .tutorial
                        )
                    }
                }
                .overlay {
                    if model.phase == .tutorial && model.tutorialStep == .pond {
                        RoundedRectangle(cornerRadius: GameHUDView.panelCornerRadius).stroke(.yellow, lineWidth: 3)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if model.settings.showsDirectionalPad || voiceOverEnabled {
                DirectionalPadView(
                    isEnabled: model.phase == .playing || model.tutorialCanMove,
                    onMove: model.move
                )
                .padding(16)
            }
        }
        .overlay {
            if model.scene != nil {
                GamePhaseOverlayView(model: model, onSettings: onSettings)
                    .allowsHitTesting(model.phase != .playing)
            }
        }
        .task(id: reduceMotion) {
            model.setReduceMotion(reduceMotion)
        }
    }
}
