import Foundation

nonisolated struct GameLaunchOptions: Equatable, Sendable {
    let seed: UInt64?
    let maximumBreath: Double?
    let showsDirectionalPad: Bool
    let resetsProgress: Bool

    init(arguments: [String]) {
        seed = Self.value(after: "--finhopper-seed=", in: arguments).flatMap(UInt64.init)
        maximumBreath = Self.value(after: "--finhopper-breath=", in: arguments)
            .flatMap(Double.init)
            .flatMap { $0 > 0 ? $0 : nil }
        showsDirectionalPad = arguments.contains("--finhopper-show-dpad")
        resetsProgress = arguments.contains("--finhopper-reset-progress")
    }

    static var current: GameLaunchOptions {
        #if DEBUG
        GameLaunchOptions(arguments: ProcessInfo.processInfo.arguments)
        #else
        GameLaunchOptions(arguments: [])
        #endif
    }

    private static func value(after prefix: String, in arguments: [String]) -> String? {
        arguments.first { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
    }
}
