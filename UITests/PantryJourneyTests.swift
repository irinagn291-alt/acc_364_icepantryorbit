import XCTest

final class PantryJourneyTests: XCTestCase {
    func testShelfUseAndRestock() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-registration_attempted", "YES", "-cached_content_url", ""]
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["PANTRY_UI_TEST_SUITE"] = "pantry-tests." + UUID().uuidString
        app.launch()

        func addBatch(_ name: String, quantity: Int, catalog: Bool = false) {
            app.buttons["Add a batch"].tap()
            let field = app.textFields["batch.name"]
            XCTAssertTrue(field.waitForExistence(timeout: 10))
            if catalog {
                app.buttons["Search or scan a barcode"].tap()
                let result = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
                XCTAssertTrue(result.waitForExistence(timeout: 10))
                result.tap()
            } else {
                field.tap()
                field.typeText(name)
            }
            for _ in 1..<quantity { app.buttons["Increase quantity"].tap() }
            let save = app.buttons["batch.save"]
            for _ in 0..<4 where !save.isHittable { app.swipeUp() }
            XCTAssertTrue(save.isEnabled)
            save.tap()
            XCTAssertTrue(app.buttons["Add a batch"].waitForExistence(timeout: 8))
        }

        let name = "Cannellini beans"
        addBatch(name, quantity: 3)
        let batch = app.buttons["batch.row." + name].firstMatch
        XCTAssertTrue(batch.waitForExistence(timeout: 8))
        batch.tap()
        let restock = app.switches["Add to shopping list"]
        for _ in 0..<3 where !restock.isHittable { app.swipeUp() }
        restock.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(restock.value as? String, "1")
        let record = app.buttons["Record use"]
        for _ in 0..<3 where !record.isHittable { app.swipeUp() }
        record.tap()
        XCTAssertTrue(app.buttons["Add a batch"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Market"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch.waitForExistence(timeout: 8))
        app.tabBars.buttons["Ledger"].tap()
        XCTAssertTrue(app.staticTexts[name].firstMatch.waitForExistence(timeout: 8))
        app.tabBars.buttons["Shelves"].tap()
        addBatch("Quaker", quantity: 2, catalog: true)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "PantryOrbit-preview"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["batch.row." + name].firstMatch.waitForExistence(timeout: 10))
    }
}
