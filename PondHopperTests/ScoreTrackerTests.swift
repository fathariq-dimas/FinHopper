import Testing
@testable import FinHopper

struct ScoreTrackerTests {
    @Test
    func lateralAndBackwardRowsCannotIncreaseScore() {
        var tracker = ScoreTracker()

        let reachedRowFour = tracker.record(row: 4)
        let repeatedRowFour = tracker.record(row: 4)
        let movedBackward = tracker.record(row: 2)

        #expect(reachedRowFour)
        #expect(!repeatedRowFour)
        #expect(!movedBackward)
        #expect(tracker.highestRow == 4)

        let reachedRowFive = tracker.record(row: 5)
        #expect(reachedRowFive)
        #expect(tracker.highestRow == 5)
    }
}
