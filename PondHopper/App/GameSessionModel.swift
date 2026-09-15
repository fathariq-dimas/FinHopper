import Combine
import SwiftUI

@MainActor
final class GameSessionModel: ObservableObject, GameSceneEventSink {
    @Published private(set) var tutorialStep: TutorialStep = .movement(0)
    @Published private(set) var tutorialPaused = false
    @Published private(set) var tutorialFailure: GameOverReason?
    private var reduceMotion = false
    private var completedTutorialThisLaunch = false
    var tutorialCanMove: Bool { phase == .tutorial && !tutorialPaused && tutorialFailure == nil }
    @Published private(set) var phase: GamePhase = .menu
    @Published private(set) var snapshot: GameSnapshot
    @Published private(set) var scene: GameScene?
    @Published var settings: GameSettings {
        didSet {
            persistence.settings = settings
            music.setSoundEnabled(settings.soundEnabled)
        }
    }

    let config: GameConfig

    private let persistence: any GamePersisting
    private let launchOptions: GameLaunchOptions
    private let feedback: any GameFeedbackPerforming
    private let music = GameMusicService()
    private var resumesTutorial = false
    private var countdownTask: Task<Void, Never>?

    init(
        persistence: any GamePersisting = UserDefaultsGamePersistence(),
        config: GameConfig? = nil,
        launchOptions: GameLaunchOptions = .current,
        feedback: any GameFeedbackPerforming = GameFeedbackService()
    ) {
        self.persistence = persistence
        self.launchOptions = launchOptions
        self.feedback = feedback

        if launchOptions.resetsProgress {
            persistence.bestScore = 0
            persistence.hasSeenTutorial = false
            persistence.settings = .defaults
            persistence.lastRunSeed = nil
        }

        let resolvedConfig = (config ?? .live)
            .replacingMaximumBreath(with: config == nil ? launchOptions.maximumBreath : nil)
        self.config = resolvedConfig
        var resolvedSettings = persistence.settings
        if launchOptions.showsDirectionalPad {
            resolvedSettings.showsDirectionalPad = true
        }
        settings = resolvedSettings
        snapshot = .initial(bestScore: persistence.bestScore, config: resolvedConfig)
        feedback.preload()
        music.preload()
        prepareWaitingRun()
    }

    func startRun(with initialMovement: MoveDirection = .up) {
        guard phase == .menu else { return }
        if completedTutorialThisLaunch {
            enterPlayingPhase()
        } else {
            phase = .tutorial
            syncTutorialScene()
        }
    }

    private func syncTutorialScene() {
        scene?.setTutorialStep(tutorialStep)
        scene?.setGameplayRunning(tutorialCanMove)
        scene?.setSimulationPaused(!tutorialCanMove)
    }

    func continueTutorial() {
        guard phase == .tutorial else { return }
        if tutorialFailure != nil {
            tutorialFailure = nil
            tutorialPaused = false
            scene?.retryTutorialArea()
            music.resume(soundEnabled: settings.soundEnabled)
            syncTutorialScene()
            return
        }
        guard tutorialPaused else { return }
        tutorialPaused = false
        music.resume(soundEnabled: settings.soundEnabled)
        syncTutorialScene()
    }

    private func tutorialFailed(_ reason: GameOverReason) {
        tutorialFailure = reason
        scene?.setSimulationPaused(true)
    }

    func pause() {
        if phase == .tutorial {
            tutorialPaused = true
            scene?.setSimulationPaused(true)
            music.pause()
            return
        }
        guard phase == .playing else { return }
        countdownTask?.cancel()
        scene?.setSimulationPaused(true)
        phase = .paused
        music.pause()
    }

    func resume() {
        guard phase == .paused || (phase == .tutorial && tutorialPaused && tutorialFailure == nil) else { return }
        resumesTutorial = phase == .tutorial
        music.resume(soundEnabled: settings.soundEnabled)
        beginCountdown()
    }

    func restart() {
        guard phase != .menu else { return }
        prepareWaitingRun()
        startRun()
    }

    func returnToWaiting() {
        countdownTask?.cancel()
        scene = nil
        phase = .menu

        Task { [weak self] in
            await Task.yield()
            guard let self, phase == .menu, scene == nil else { return }
            prepareWaitingRun()
        }
    }

    func move(_ direction: MoveDirection) {
        guard phase == .playing || tutorialCanMove else { return }
        scene?.enqueueMovement(direction)
    }

    func setReduceMotion(_ isEnabled: Bool) {
        reduceMotion = isEnabled
        scene?.setReduceMotion(isEnabled)
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        guard scenePhase != .active else {
            music.resume(soundEnabled: settings.soundEnabled)
            return
        }

        switch phase {
        case .playing, .countdown:
            countdownTask?.cancel()
            scene?.setSimulationPaused(true)
            phase = resumesTutorial ? .tutorial : .paused
            music.pause()
        case .tutorial:
            pause()
        case .menu, .paused, .gameOver:
            music.pause()
        }
    }

    func receive(_ event: GameEvent) {
        switch event {
        case .scoreChanged(let score):
            guard phase != .tutorial else { return }
            snapshot.score = max(snapshot.score, score)
        case .breathChanged(let breath):
            snapshot.breathRemaining = min(max(0, breath), config.maximumBreath)
        case .targetDirectionChanged(let direction):
            snapshot.targetDirection = direction
        case .feedback(let event):
            feedback.perform(event, settings: settings)
        case .gameOver(let reason):
            if phase == .tutorial { tutorialFailed(reason) }
            else { finishRun(reason: reason) }
        case .tutorialWrongInput, .movementBlocked:
            break
        case .movementCompleted(let position):
            guard tutorialCanMove else { return }
            switch tutorialStep {
            case .movement(let index):
                let center = config.columns / 2
                let targets = TutorialStep.movementTargets(center: center)
                guard position == targets[index] else { return }
                tutorialStep = index == targets.count - 1 ? .traffic : .movement(index + 1)
            case .traffic where position.row >= 8:
                tutorialStep = .pond
            default: break
            }
            syncTutorialScene()
        case .pondAbsorbed:
            guard tutorialCanMove, tutorialStep == .pond else { return }
            completedTutorialThisLaunch = true
            scene?.finishTutorial()
            snapshot.score = 0
            enterPlayingPhase()
        }
    }

    private func prepareWaitingRun() {
        countdownTask?.cancel()
        resumesTutorial = false
        phase = .menu
        tutorialStep = .movement(0)
        tutorialPaused = false
        tutorialFailure = nil

        let seed = launchOptions.seed ?? UInt64.random(in: UInt64.min...UInt64.max)
        persistence.lastRunSeed = seed
        snapshot = .initial(bestScore: persistence.bestScore, config: config)
        snapshot.seed = seed
        scene = GameScene(config: config, seed: seed, eventSink: self,
            tutorialSection: completedTutorialThisLaunch ? nil : 1)
        scene?.setReduceMotion(reduceMotion)
        scene?.setGameplayRunning(false)
        music.play(soundEnabled: settings.soundEnabled)
    }

    private func beginCountdown() {
        countdownTask?.cancel()

        guard config.countdownSeconds > 0 else {
            finishResumeCountdown()
            return
        }

        // Leave the paused phase synchronously so the pause overlay is replaced
        // by the countdown in the same update, and keep the scene frozen until
        // the countdown actually reaches zero.
        phase = .countdown(config.countdownSeconds)

        countdownTask = Task { [weak self] in
            guard let self else { return }

            for value in stride(from: config.countdownSeconds, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                phase = .countdown(value)
                feedback.perform(.countdown, settings: settings)

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }
            finishResumeCountdown()
        }
    }

    private func finishResumeCountdown() {
        if resumesTutorial {
            resumesTutorial = false
            phase = .tutorial
            tutorialPaused = false
            syncTutorialScene()
        } else {
            enterPlayingPhase()
        }
    }

    private func enterPlayingPhase() {
        phase = .playing
        scene?.setGameplayRunning(true)
    }

    private func finishRun(reason: GameOverReason) {
        guard phase == .playing else { return }

        if snapshot.score > persistence.bestScore {
            persistence.bestScore = snapshot.score
        }
        snapshot.bestScore = persistence.bestScore
        scene?.setGameplayRunning(false)
        phase = .gameOver(reason)
        music.stop()
    }
}
