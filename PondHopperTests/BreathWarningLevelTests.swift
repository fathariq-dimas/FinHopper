import Testing
@testable import FinHopper

struct BreathWarningLevelTests {
    @Test
    func resolvesCautionAndDangerAtConfiguredFractions() {
        #expect(BreathWarningLevel.resolve(remaining: 4.1, maximum: 10, isActive: true) == .none)
        #expect(BreathWarningLevel.resolve(remaining: 4, maximum: 10, isActive: true) == .caution)
        #expect(BreathWarningLevel.resolve(remaining: 2.1, maximum: 10, isActive: true) == .caution)
        #expect(BreathWarningLevel.resolve(remaining: 2, maximum: 10, isActive: true) == .danger)
        #expect(BreathWarningLevel.resolve(remaining: 0, maximum: 10, isActive: true) == .danger)
    }

    @Test
    func remainsHiddenOutsideActiveGameplayOrWithoutValidMaximum() {
        #expect(BreathWarningLevel.resolve(remaining: 1, maximum: 10, isActive: false) == .none)
        #expect(BreathWarningLevel.resolve(remaining: 0, maximum: 0, isActive: true) == .none)
    }
}
