import Testing
@testable import FinHopper

struct GameLaunchOptionsTests {
    @Test
    func parsesDeterministicDebugOverrides() {
        let options = GameLaunchOptions(arguments: [
            "FinHopper",
            "--finhopper-seed=12345",
            "--finhopper-breath=60",
            "--finhopper-skip-tutorial",
            "--finhopper-show-dpad",
            "--finhopper-reset-progress"
        ])

        #expect(options.seed == 12_345)
        #expect(options.maximumBreath == 60)
        #expect(options.showsDirectionalPad)
        #expect(options.resetsProgress)
    }

    @Test
    func rejectsInvalidBreathOverride() {
        let options = GameLaunchOptions(arguments: ["--finhopper-breath=-2"])

        #expect(options.maximumBreath == nil)
    }
}
