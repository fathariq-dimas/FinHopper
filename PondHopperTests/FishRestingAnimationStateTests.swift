import Testing
@testable import FinHopper

struct FishRestingAnimationStateTests {
    @Test
    func activePondAlwaysUsesRecoveryAnimation() {
        let state = FishRestingAnimationState.resolve(
            remainingBreath: 1,
            maximumBreath: 10,
            isOnActivePond: true
        )

        #expect(state == .pondRecovery)
    }

    @Test
    func dryLandTransitionsFromCautionToDangerAtWarningThresholds() {
        let aboveCaution = FishRestingAnimationState.resolve(
            remainingBreath: 4.01,
            maximumBreath: 10,
            isOnActivePond: false
        )
        let atCaution = FishRestingAnimationState.resolve(
            remainingBreath: 4,
            maximumBreath: 10,
            isOnActivePond: false
        )
        let aboveDanger = FishRestingAnimationState.resolve(
            remainingBreath: 2.01,
            maximumBreath: 10,
            isOnActivePond: false
        )
        let atDanger = FishRestingAnimationState.resolve(
            remainingBreath: 2,
            maximumBreath: 10,
            isOnActivePond: false
        )

        #expect(aboveCaution == .landIdle)
        #expect(atCaution == .cautionBreath)
        #expect(aboveDanger == .cautionBreath)
        #expect(atDanger == .dangerBreath)
    }

    @Test
    func invalidMaximumDoesNotEnterWarningAnimation() {
        let state = FishRestingAnimationState.resolve(
            remainingBreath: 0,
            maximumBreath: 0,
            isOnActivePond: false
        )

        #expect(state == .landIdle)
    }
}
