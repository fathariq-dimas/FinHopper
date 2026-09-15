import AVFoundation
import Testing
@testable import FinHopper

struct BundledGameAudioTests {
    @Test
    func vehicleRecordingFinishesBeforeAnotherPassCanPlay() throws {
        let url = try #require(Bundle.main.url(forResource: "vehiclePass", withExtension: "wav"))
        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.fileFormat.sampleRate
        #expect(duration <= VehiclePassByTracker.cooldown)
        #expect(duration > 2)
    }

    @Test
    func everySoundEffectIsBundledAsValidMonoPCM() throws {
        for effect in GameSoundEffect.allCases {
            let url = try #require(
                Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                "Missing \(effect.rawValue).wav"
            )
            let file = try AVAudioFile(forReading: url)

            #expect(file.length > 0)
            #expect(file.fileFormat.channelCount == 1)
            #expect(file.fileFormat.sampleRate == 44_100)
        }
    }
}
