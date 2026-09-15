import Testing
@testable import FinHopper

struct BreathMeterTests {
    @Test
    func laterPondCanBeVisitedWithoutVisitingEarlierPonds() {
        var meter = BreathMeter(maximum: 10)
        let didVisit = meter.visitPond(id: 4)

        #expect(didVisit)
        #expect(meter.visitedPondIDs == [4])
        #expect(!meter.visitedPondIDs.contains(1))
    }

    @Test
    func drainsOnlyOutsidePondAndExpiresOnce() {
        var meter = BreathMeter(maximum: 10)

        let expiredWhileSafe = meter.advance(by: 2, isSafe: true)
        #expect(!expiredWhileSafe)
        #expect(meter.remaining == 10)

        let expiredAtTwoSeconds = meter.advance(by: 8, isSafe: false)
        #expect(!expiredAtTwoSeconds)
        #expect(meter.remaining == 2)

        let expiredAtZero = meter.advance(by: 2, isSafe: false)
        #expect(expiredAtZero)
        #expect(meter.remaining == 0)

        let expiredAgain = meter.advance(by: 1, isSafe: false)
        #expect(!expiredAgain)
    }

    @Test
    func eachPondAddsBreathOnlyOnce() {
        var meter = BreathMeter(maximum: 10)
        _ = meter.advance(by: 6, isSafe: false)

        let firstVisit = meter.visitPond(id: 42)
        #expect(firstVisit)
        #expect(meter.remaining == 9)

        _ = meter.advance(by: 4, isSafe: false)
        let repeatVisit = meter.visitPond(id: 42)
        #expect(!repeatVisit)
        #expect(meter.remaining == 5)

        let differentPondVisit = meter.visitPond(id: 43)
        #expect(differentPondVisit)
        #expect(meter.remaining == 10)
    }
    @Test func additionsClampAtTenWithoutBankingExcess() {
        var meter = BreathMeter(maximum: 10)
        meter.advance(by: 7, isSafe: false)
        meter.visitPond(id: 1, adding: PondKind.small.addedSeconds)
        #expect(meter.remaining == 8)
        meter.visitPond(id: 2, adding: PondKind.small.addedSeconds)
        #expect(meter.remaining == 10)
        meter.advance(by: 8, isSafe: false)
        #expect(meter.remaining == 2)
        meter.visitPond(id: 3, adding: PondKind.large.addedSeconds)
        #expect(meter.remaining == 10)
        meter.advance(by: 3, isSafe: false)
        let repeated = meter.visitPond(id: 3, adding: 10)
        #expect(!repeated)
        #expect(meter.remaining == 7)
    }

}
