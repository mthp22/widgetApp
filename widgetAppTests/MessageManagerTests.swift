import Foundation
import XCTest
@testable import widgetApp

@MainActor
final class MessageManagerTests: XCTestCase {
    private func makeManager(
        repository: MessageRepository
    ) -> (MessageManager, RecordingWidgetReloader) {
        let reloader = RecordingWidgetReloader()
        let manager = MessageManager(
            repository: repository,
            resolver: TestClock.resolver(),
            widgetReloader: reloader
        )
        return (manager, reloader)
    }

    // MARK: - Creating

    func testCreatePersistsTrimsContentAndRefreshesTheWidget() throws {
        let repository = InMemoryMessageRepository()
        let (manager, reloader) = makeManager(repository: repository)

        try manager.createMessage(
            content: "  Focus block  ",
            scheduledDate: nil,
            repeatDays: nil,
            style: .bold
        )

        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertEqual(manager.messages.first?.content, "Focus block")
        XCTAssertEqual(repository.stored, manager.messages)
        XCTAssertEqual(repository.saveCount, 1)
        XCTAssertEqual(reloader.reloadCount, 1)
        XCTAssertNil(manager.lastPersistenceError)
    }

    func testCreateRejectsEmptyContentWithoutTouchingStorage() {
        let repository = InMemoryMessageRepository()
        let (manager, reloader) = makeManager(repository: repository)

        XCTAssertThrowsError(
            try manager.createMessage(content: "   ", scheduledDate: nil, repeatDays: nil, style: .bold)
        ) { error in
            XCTAssertEqual(error as? MessageManagerError, .emptyContent)
        }

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertEqual(repository.saveCount, 0)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func testCreateRejectsRepeatingMessageWithoutATime() {
        let repository = InMemoryMessageRepository()
        let (manager, _) = makeManager(repository: repository)

        XCTAssertThrowsError(
            try manager.createMessage(
                content: "Repeat me",
                scheduledDate: nil,
                repeatDays: [1, 3],
                style: .casual
            )
        ) { error in
            XCTAssertEqual(error as? MessageManagerError, .missingRepeatingTime)
        }

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertEqual(repository.saveCount, 0)
    }

    // MARK: - Updating

    func testUpdateReplacesTheStoredValue() throws {
        let existing = Message(
            content: "Old",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .formal
        )
        let repository = InMemoryMessageRepository(seed: [existing])
        let (manager, reloader) = makeManager(repository: repository)

        var updated = existing
        updated.content = "New"
        updated.widgetStyle = .casual
        try manager.updateMessage(updated)

        XCTAssertEqual(manager.messages.first?.content, "New")
        XCTAssertEqual(manager.messages.first?.widgetStyle, .casual)
        XCTAssertEqual(repository.stored.first?.content, "New")
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testUpdateOfUnknownMessageFails() {
        let (manager, _) = makeManager(repository: InMemoryMessageRepository())

        let unknown = Message(content: "Ghost", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)

        XCTAssertThrowsError(try manager.updateMessage(unknown)) { error in
            XCTAssertEqual(error as? MessageManagerError, .messageNotFound)
        }
    }

    // MARK: - Deleting

    func testDeleteRemovesTheMessageFromMemoryAndStorage() throws {
        let message = Message(content: "Delete me", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let repository = InMemoryMessageRepository(seed: [message])
        let (manager, reloader) = makeManager(repository: repository)

        try manager.deleteMessage(id: message.id)

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertTrue(repository.stored.isEmpty)
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testDeleteAllMessagesEmptiesStorageAndRefreshesTheWidget() throws {
        let repository = InMemoryMessageRepository(seed: [
            Message(content: "One", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold),
            Message(content: "Two", scheduledDate: nil, repeatDays: nil, widgetStyle: .casual),
            Message(content: "Three", scheduledDate: nil, repeatDays: nil, widgetStyle: .formal)
        ])
        let (manager, reloader) = makeManager(repository: repository)

        try manager.deleteAllMessages()

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertTrue(repository.stored.isEmpty)
        XCTAssertEqual(repository.saveCount, 1)
        XCTAssertEqual(reloader.reloadCount, 1)
        XCTAssertNil(manager.lastPersistenceError)
    }

    func testDeleteAllMessagesOnAnEmptyLibraryWritesNothing() throws {
        let repository = InMemoryMessageRepository()
        let (manager, reloader) = makeManager(repository: repository)

        try manager.deleteAllMessages()

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertEqual(repository.saveCount, 0)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func testDeleteAllMessagesSurfacesAStorageFailure() throws {
        let repository = InMemoryMessageRepository(seed: [
            Message(content: "Kept for now", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        ])
        let (manager, reloader) = makeManager(repository: repository)
        repository.errorToThrow = NSError(
            domain: "WhisperWidgetTests",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Disk full"]
        )

        XCTAssertThrowsError(try manager.deleteAllMessages())

        // The write failed, so the UI must keep showing what is really stored.
        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertNotNil(manager.lastPersistenceError)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    // MARK: - Failure handling

    func testFailedSaveKeepsInMemoryStateConsistentAndSurfacesTheError() throws {
        let first = Message(content: "First", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let repository = InMemoryMessageRepository(seed: [first])
        let (manager, reloader) = makeManager(repository: repository)

        repository.errorToThrow = NSError(domain: "WhisperWidgetTests", code: 3, userInfo: [NSLocalizedDescriptionKey: "Disk full"])

        XCTAssertThrowsError(
            try manager.createMessage(content: "Second", scheduledDate: nil, repeatDays: nil, style: .casual)
        )

        // The failed write must not leave the UI showing a message that was
        // never persisted.
        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertNotNil(manager.lastPersistenceError)
        XCTAssertEqual(reloader.reloadCount, 0)
    }

    func testFailedLoadRecordsAVisibleError() {
        let (manager, _) = makeManager(repository: FailingMessageRepository())

        XCTAssertTrue(manager.messages.isEmpty)
        XCTAssertNotNil(manager.lastPersistenceError)
    }

    // MARK: - Reading

    func testReloadPicksUpExternalChanges() throws {
        let repository = InMemoryMessageRepository()
        let (manager, reloader) = makeManager(repository: repository)

        repository.errorToThrow = nil
        try repository.saveMessages([
            Message(content: "Written elsewhere", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        ])

        try manager.reload()

        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertEqual(reloader.reloadCount, 0, "Reloading is a read, not a data change")
    }

    func testSchedulingQueriesDelegateToTheResolver() {
        let message = Message(
            content: "Tomorrow",
            scheduledDate: TestClock.date(2026, 1, 6, 9, 0),
            repeatDays: nil,
            widgetStyle: .bold
        )
        let repository = InMemoryMessageRepository(seed: [message])
        let (manager, _) = makeManager(repository: repository)

        let reference = TestClock.date(2026, 1, 5, 8, 0)

        XCTAssertEqual(manager.scheduledDate(for: message, after: reference), TestClock.date(2026, 1, 6, 9, 0))
        XCTAssertEqual(manager.nextScheduledEntry(at: reference)?.message.id, message.id)
        XCTAssertEqual(manager.currentDisplay(at: reference)?.message.id, message.id)
    }

    func testRefreshWidgetAsksTheReloaderDirectly() {
        let (manager, reloader) = makeManager(repository: InMemoryMessageRepository())

        manager.refreshWidget()

        XCTAssertEqual(reloader.reloadCount, 1)
    }
}

@MainActor
final class MessageComposerViewModelTests: XCTestCase {
    func testSavingANewMessagePersistsThroughTheManager() throws {
        let repository = InMemoryMessageRepository()
        let reloader = RecordingWidgetReloader()
        let manager = MessageManager(
            repository: repository,
            resolver: TestClock.resolver(),
            widgetReloader: reloader
        )
        let viewModel = MessageComposerViewModel(now: TestClock.date(2026, 1, 5, 8, 0))

        viewModel.content = "  Write the report  "
        viewModel.selectedStyle = .formal
        viewModel.isDateEnabled = false

        XCTAssertTrue(viewModel.save(using: manager))
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.stored.first?.content, "Write the report")
        XCTAssertEqual(repository.stored.first?.widgetStyle, .formal)
        XCTAssertNil(repository.stored.first?.scheduledDate)
        XCTAssertEqual(reloader.reloadCount, 1)
    }

    func testSavingAnInvalidMessageSurfacesTheError() {
        let repository = InMemoryMessageRepository()
        let manager = MessageManager(
            repository: repository,
            resolver: TestClock.resolver(),
            widgetReloader: RecordingWidgetReloader()
        )
        let viewModel = MessageComposerViewModel(now: TestClock.date(2026, 1, 5, 8, 0))

        viewModel.content = "     "

        XCTAssertFalse(viewModel.save(using: manager))
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(repository.stored.isEmpty)
    }

    func testEditingAnExistingMessageUpdatesItInsteadOfDuplicating() throws {
        let existing = Message(
            content: "Original",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .bold
        )
        let repository = InMemoryMessageRepository(seed: [existing])
        let manager = MessageManager(
            repository: repository,
            resolver: TestClock.resolver(),
            widgetReloader: RecordingWidgetReloader()
        )
        let viewModel = MessageComposerViewModel(initialMessage: existing)

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.content, "Original")

        viewModel.content = "Edited"
        XCTAssertTrue(viewModel.save(using: manager))

        XCTAssertEqual(repository.stored.count, 1)
        XCTAssertEqual(repository.stored.first?.content, "Edited")
        XCTAssertEqual(repository.stored.first?.id, existing.id)
        XCTAssertFalse(viewModel.isEditing)
    }

    func testRepeatingMessagesAlwaysKeepAScheduleTime() {
        let viewModel = MessageComposerViewModel(now: TestClock.date(2026, 1, 5, 8, 0))

        viewModel.isDateEnabled = false
        viewModel.repeatDays = [RepeatDay.friday.rawValue]

        XCTAssertNotNil(viewModel.resolvedScheduledDate)
    }

    func testDeletingTheEditedMessageRemovesIt() throws {
        let existing = Message(
            content: "Remove",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .casual
        )
        let repository = InMemoryMessageRepository(seed: [existing])
        let manager = MessageManager(
            repository: repository,
            resolver: TestClock.resolver(),
            widgetReloader: RecordingWidgetReloader()
        )
        let viewModel = MessageComposerViewModel(initialMessage: existing)

        XCTAssertTrue(viewModel.delete(using: manager))
        XCTAssertTrue(repository.stored.isEmpty)
        XCTAssertFalse(viewModel.isEditing)
    }
}
