import XCTest

/// Captures App Store screenshots. Skipped unless STORE_SHOTS=1 and expects a
/// fresh install (uninstall the app first) so onboarding is shown.
final class StoreScreenshotsUITests: XCTestCase {
    func testStoreScreenshots() throws {
        let env = ProcessInfo.processInfo.environment
        try XCTSkipUnless(env["STORE_SHOTS"] == "1", "Set STORE_SHOTS=1 to capture store screenshots")
        let lang = env["STORE_LANG"] ?? "en"

        let app = XCUIApplication()
        app.launchArguments += ["-app.language", lang, "-themeMode", "dark"]
        app.launch()

        let generate = app.buttons["onboarding.generateButton"]
        XCTAssertTrue(generate.waitForExistence(timeout: 10))
        snap("1-onboarding")

        generate.tap()
        let start = app.buttons["plan.startWorkout"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        sleep(1)
        snap("2-plan")

        let thumb = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'exercise.demoThumbnail.'")).firstMatch
        if thumb.waitForExistence(timeout: 5) {
            thumb.tap()
            sleep(2)
            snap("3-exercise-demo")
            app.swipeDown(velocity: .fast)
            sleep(1)
        }

        start.tap()
        sleep(2)
        snap("4-workout-session")
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
