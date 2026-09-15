import Testing
@testable import FinHopper

@MainActor
struct GameSessionModelTests {
    @Test
    func firstRunStartsMandatoryTutorialFromWaitingView() {
        let persistence = MemoryGamePersistence()
        let model = GameSessionModel(
            persistence: persistence,
            config: instantConfig,
            feedback: RecordingGameFeedback()
        )

        #expect(model.phase == .menu)
        #expect(model.scene != nil)
        #expect(model.snapshot.seed != nil)

        model.startRun(with: .left)

        #expect(model.phase == .tutorial)
        #expect(model.tutorialStep == .movement(0))
    }

    @Test
    func scoreOnlyMovesForwardAndPersistsAtGameOver() {
        let persistence = MemoryGamePersistence()
        persistence.hasSeenTutorial = true
        let model = GameSessionModel(
            persistence: persistence,
            config: instantConfig,
            feedback: RecordingGameFeedback()
        )

        model.startRun()
        completeTutorial(model)
        model.receive(.scoreChanged(8))
        model.receive(.scoreChanged(3))
        model.receive(.gameOver(.vehicleCollision))

        #expect(model.snapshot.score == 8)
        #expect(model.snapshot.bestScore == 8)
        #expect(persistence.bestScore == 8)
        #expect(model.phase == .gameOver(.vehicleCollision))
    }

    @Test
    func leavingActiveScenePausesRun() {
        let persistence = MemoryGamePersistence()
        persistence.hasSeenTutorial = true
        let model = GameSessionModel(
            persistence: persistence,
            config: instantConfig,
            feedback: RecordingGameFeedback()
        )

        model.startRun()
        completeTutorial(model)
        model.handleScenePhase(.background)

        #expect(model.phase == .paused)
    }

    @Test
    func gameOverPlayTransitionsThroughLoadingToFreshWaitingScene() async {
        let persistence = MemoryGamePersistence()
        let model = GameSessionModel(
            persistence: persistence,
            config: instantConfig,
            feedback: RecordingGameFeedback()
        )

        model.startRun()
        completeTutorial(model)
        let firstScene = model.scene
        model.receive(.gameOver(.vehicleCollision))
        model.returnToWaiting()

        #expect(model.scene == nil)
        #expect(model.phase == .menu)

        for _ in 0..<20 where model.scene == nil { await Task.yield() }

        #expect(model.scene != nil)
        #expect(firstScene !== model.scene)
        #expect(model.phase == .menu)
    }

    @Test
    func sceneFeedbackUsesCurrentSettings() {
        let persistence = MemoryGamePersistence()
        let feedback = RecordingGameFeedback()
        let model = GameSessionModel(
            persistence: persistence,
            config: instantConfig,
            feedback: feedback
        )
        model.settings.soundEnabled = false

        model.receive(.feedback(.hop))

        #expect(feedback.preloadCallCount == 1)
        #expect(feedback.events == [.hop])
        #expect(feedback.receivedSettings == [model.settings])
    }

    @Test
    func countdownEmitsFeedbackBeforePlayBegins() async {
        let persistence = MemoryGamePersistence()
        persistence.hasSeenTutorial = true
        let feedback = RecordingGameFeedback()
        let model = GameSessionModel(
            persistence: persistence,
            config: countdownConfig,
            feedback: feedback
        )

        model.startRun()
        completeTutorial(model)
        model.pause()
        model.resume()
        await Task.yield()

        #expect(model.phase == .countdown(1))
        #expect(feedback.events == [.countdown])
        model.returnToWaiting()
    }

    @Test func tutorialPauseResumesAndRetryStartsFreshTutorial() {
        let model = GameSessionModel(persistence: MemoryGamePersistence(),
            config: instantConfig, feedback: RecordingGameFeedback())
        model.startRun()
        let firstScene = model.scene
        model.pause()
        #expect(model.tutorialPaused)
        model.resume()
        #expect(model.phase == .tutorial)
        #expect(!model.tutorialPaused)
        #expect(model.scene === firstScene)
        model.pause()
        model.restart()
        #expect(model.phase == .tutorial)
        #expect(model.scene !== firstScene)
        #expect(!model.tutorialPaused)
        #expect(model.tutorialStep == .movement(0))
    }

    @Test func tutorialResumeCountdownSurvivesBackgroundWithoutStartingGameplay() async {
        let model = GameSessionModel(persistence: MemoryGamePersistence(),
            config: countdownConfig, feedback: RecordingGameFeedback())
        model.startRun()
        model.pause()
        model.resume()
        #expect(model.phase == .countdown(1))
        model.handleScenePhase(.background)
        #expect(model.phase == .tutorial)
        #expect(model.tutorialPaused)
        #expect(!model.tutorialCanMove)
        model.resume()
        try? await Task.sleep(for: .milliseconds(1200))
        #expect(model.phase == .tutorial)
        #expect(model.tutorialCanMove)
    }

    private var instantConfig: GameConfig {
        GameConfig(
            columns: 9,
            movementDuration: 0.12,
            maximumBreath: 10,
            countdownSeconds: 0,
            rowsPerDifficultyTier: 20,
            maximumDifficultyTier: 6
        )
    }

    private var countdownConfig: GameConfig {
        GameConfig(
            columns: 9,
            movementDuration: 0.12,
            maximumBreath: 10,
            countdownSeconds: 1,
            rowsPerDifficultyTier: 20,
            maximumDifficultyTier: 6
        )
    }
}
