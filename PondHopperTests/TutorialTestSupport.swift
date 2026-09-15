@testable import FinHopper

@MainActor
func completeTutorial(_ model: GameSessionModel) {
    let center = model.config.columns / 2
    for target in TutorialStep.movementTargets(center: center) {
        model.receive(.movementCompleted(target))
    }
    model.receive(.movementCompleted(.init(column: center - 1, row: 8)))
    model.receive(.pondAbsorbed)
}
