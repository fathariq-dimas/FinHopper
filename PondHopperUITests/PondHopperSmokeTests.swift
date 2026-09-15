import XCTest

@MainActor
final class FinHopperSmokeTests: XCTestCase {
    func testLaunchShowsWaitingGameView() {
        let app = XCUIApplication()
        app.launchArguments = ["--finhopper-reset-progress"]
        app.launch()

        XCTAssertTrue(app.images["mainMenu.play"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["mainMenu.settings"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["game.field"].exists)
    }

    func testFirstRunStartsDirectly() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--finhopper-reset-progress",
            "--finhopper-seed=42",
            "--finhopper-breath=60"
        ]
        app.launch()

        app.images["mainMenu.play"].tap()
        XCTAssertFalse(app.staticTexts["game.countdown"].exists)
        XCTAssertTrue(waitUntilEnabled(app.buttons["game.pause"], timeout: 2))
    }

    func testAccessibilityTextSizeKeepsPrimaryControlsReachable() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--finhopper-reset-progress",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
        app.launch()

        XCTAssertTrue(app.images["mainMenu.play"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.images["mainMenu.play"].isHittable)
        XCTAssertTrue(app.buttons["mainMenu.settings"].isHittable)
    }

    func testPlayMovePauseAndResume() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--finhopper-reset-progress",
            "--finhopper-skip-tutorial",
            "--finhopper-breath=60",
            "--finhopper-seed=42",
            "--finhopper-show-dpad"
        ]
        app.launch()

        app.buttons["mainMenu.settings"].tap()
        let directionalPadToggle = app.switches["Show Directional Pad"]
        XCTAssertTrue(directionalPadToggle.waitForExistence(timeout: 2))
        if directionalPadToggle.value as? String == "0" {
            directionalPadToggle.tap()
        }
        app.buttons["settings.done"].tap()

        app.images["mainMenu.play"].tap()

        let pauseButton = app.buttons["game.pause"]
        XCTAssertTrue(waitUntilEnabled(pauseButton, timeout: 5))

        let moveUpButton = app.buttons["dpad.up"]
        XCTAssertTrue(waitUntilEnabled(moveUpButton, timeout: 2))
        moveUpButton.tap()
        let score = app.descendants(matching: .any)
            .matching(identifier: "game.score")
            .firstMatch
        XCTAssertTrue(score.exists)
        let scoreAdvanced = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label != 'Score 0'"),
            object: score
        )
        XCTAssertEqual(XCTWaiter.wait(for: [scoreAdvanced], timeout: 2), .completed)

        pauseButton.tap()
        let resumeButton = app.buttons["pause.resume"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 2))

        resumeButton.tap()
        let pauseDisabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == false"),
            object: pauseButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [pauseDisabled], timeout: 2), .completed)
    }

    func testGameplayFieldTapMovesForward() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--finhopper-reset-progress",
            "--finhopper-skip-tutorial",
            "--finhopper-breath=60",
            "--finhopper-seed=42"
        ]
        app.launch()

        app.images["mainMenu.play"].tap()
        XCTAssertTrue(waitUntilEnabled(app.buttons["game.pause"], timeout: 5))

        let gameField = app.descendants(matching: .any)["game.field"]
        XCTAssertTrue(gameField.waitForExistence(timeout: 2))
        XCTAssertTrue(gameField.isHittable, gameField.debugDescription)
        gameField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72)).tap()

        let score = app.descendants(matching: .any)
            .matching(identifier: "game.score")
            .firstMatch
        let scoreAdvanced = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label == 'Score 1'"),
            object: score
        )
        XCTAssertEqual(XCTWaiter.wait(for: [scoreAdvanced], timeout: 2), .completed)
    }

    func testGameOverRetryAndPersistedBestScore() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--finhopper-reset-progress",
            "--finhopper-skip-tutorial",
            "--finhopper-breath=2",
            "--finhopper-seed=42",
            "--finhopper-show-dpad"
        ]
        app.launch()

        app.images["mainMenu.play"].tap()
        let pauseButton = app.buttons["game.pause"]
        XCTAssertTrue(waitUntilEnabled(pauseButton, timeout: 10))

        let moveUpButton = app.buttons["dpad.up"]
        XCTAssertTrue(waitUntilEnabled(moveUpButton, timeout: 2))
        moveUpButton.tap()

        XCTAssertTrue(app.staticTexts["gameOver.title"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["gameOver.distance"].label, "1")
        XCTAssertEqual(app.staticTexts["gameOver.bestScore"].label, "1")

        app.buttons["gameOver.retry"].tap()
        XCTAssertTrue(app.images["mainMenu.play"].waitForExistence(timeout: 3))
    }

    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND isEnabled == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
