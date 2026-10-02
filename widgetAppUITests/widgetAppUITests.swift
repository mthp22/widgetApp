import XCTest

/// End-to-end coverage of the primary flow: compose → persist → relaunch →
/// verify the message survives → delete.
///
/// The library is sorted by upcoming occurrence and rendered lazily, so the
/// test filters through the real search field to address the message it owns
/// deterministically, regardless of what else is persisted.
final class WidgetAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testComposingSavingRelaunchingAndDeletingAMessage() {
        let app = XCUIApplication()
        app.launch()

        let message = "QA \(UUID().uuidString.prefix(8)) end to end"

        openComposer(in: app)

        let field = app.descendants(matching: .any)["composer.messageField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The composer should open")
        field.tap()
        field.typeText(message)

        let saveButton = app.buttons["composer.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        // The saved message must show up in the library.
        search(for: message, in: app)
        XCTAssertTrue(
            row(for: message, in: app).waitForExistence(timeout: 5),
            "The saved message should appear in the library"
        )

        // Relaunch: the library must come back from real storage.
        app.terminate()
        app.launch()

        search(for: message, in: app)
        XCTAssertTrue(
            row(for: message, in: app).waitForExistence(timeout: 5),
            "The message should survive an app relaunch"
        )

        // Clean up through the real delete path: detail screen → Delete Message
        // → confirmation dialog, all backed by `MessageManager.deleteMessage`.
        row(for: message, in: app).tap()

        let deleteMessageButton = app.buttons["Delete Message"]
        XCTAssertTrue(deleteMessageButton.waitForExistence(timeout: 5), "The detail screen should offer deletion")
        deleteMessageButton.tap()

        let confirmDeleteButton = app.buttons["Delete"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5), "Deletion should be confirmed explicitly")
        confirmDeleteButton.tap()

        XCTAssertTrue(
            row(for: message, in: app).waitForNonExistence(timeout: 5),
            "The deleted message should disappear from the library"
        )
    }

    // MARK: - Helpers

    private func openComposer(in app: XCUIApplication) {
        let newMessageButton = app.buttons["messages.newButton"]
        if newMessageButton.waitForExistence(timeout: 5) {
            newMessageButton.tap()
            return
        }

        let composeButton = app.buttons["Compose Message"]
        XCTAssertTrue(composeButton.waitForExistence(timeout: 5), "No way to create a message was offered")
        composeButton.tap()
    }

    /// Filters the library through the app's real search field.
    private func search(for query: String, in app: XCUIApplication) {
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "The library search field should exist")
        searchField.tap()
        searchField.typeText(query)
    }

    private func row(for message: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'messageRow.' AND label CONTAINS %@", message)
        ).firstMatch
    }
}
