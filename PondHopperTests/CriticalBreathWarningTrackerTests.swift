import Testing
@testable import FinHopper

struct CriticalBreathWarningTrackerTests {
    @Test
    func warnsOncePerBreathCycleAtThirtyPercent() {
        var tracker = CriticalBreathWarningTracker(maximumBreath: 10)

        let aboveThreshold = tracker.shouldWarn(for: 3.1)
        let atThreshold = tracker.shouldWarn(for: 3)
        let repeatedWarning = tracker.shouldWarn(for: 2)

        #expect(!aboveThreshold)
        #expect(atThreshold)
        #expect(!repeatedWarning)

        tracker.reset()

        let afterReset = tracker.shouldWarn(for: 2.9)
        #expect(afterReset)
    }

    @Test
    func zeroBreathDoesNotDuplicateGameOverFeedback() {
        var tracker = CriticalBreathWarningTracker(maximumBreath: 10)

        let warning = tracker.shouldWarn(for: 0)
        #expect(!warning)
    }

    @Test
    func thresholdIsCappedAtThreeSeconds() {
        var tracker = CriticalBreathWarningTracker(maximumBreath: 60)

        let aboveThreshold = tracker.shouldWarn(for: 3.1)
        let atThreshold = tracker.shouldWarn(for: 3)

        #expect(!aboveThreshold)
        #expect(atThreshold)
    }
}
