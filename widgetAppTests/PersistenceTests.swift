import Foundation
import XCTest
@testable import widgetApp

final class PersistenceTests: XCTestCase {
    private var storageURL: URL!
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WhisperWidgetTests-\(UUID().uuidString)", isDirectory: true)
        storageURL = directory.appendingPathComponent(WhisperStorageConfiguration.fileName)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    private func makeRepository() -> SharedFileMessageRepository {
        SharedFileMessageRepository(storageURL: storageURL)
    }

    private func sampleMessages() -> [Message] {
        [
            Message(
                content: "Ship the release",
                scheduledDate: TestClock.storageSafeDate(2026, 2, 2, 9, 0),
                repeatDays: [1, 3, 5],
                widgetStyle: .bold
            ),
            Message(
                content: "Call home",
                scheduledDate: nil,
                repeatDays: nil,
                widgetStyle: .formal
            )
        ]
    }

    // MARK: - CRUD

    func testFetchingFromAnEmptyStoreReturnsNoMessages() throws {
        XCTAssertTrue(try makeRepository().fetchMessages().isEmpty)
    }

    func testCreateAndFetchRoundTripsEveryField() throws {
        let repository = makeRepository()
        let messages = sampleMessages()

        try repository.saveMessages(messages)

        XCTAssertEqual(try repository.fetchMessages(), messages)
    }

    func testUpdateReplacesTheStoredMessage() throws {
        let repository = makeRepository()
        var messages = sampleMessages()
        try repository.saveMessages(messages)

        messages[0].content = "Ship the release today"
        messages[0].widgetStyle = .casual
        try repository.saveMessages(messages)

        let stored = try repository.fetchMessages()
        XCTAssertEqual(stored.count, 2)
        XCTAssertEqual(stored[0].content, "Ship the release today")
        XCTAssertEqual(stored[0].widgetStyle, .casual)
    }

    func testDeleteRemovesOnlyTheRequestedMessage() throws {
        let repository = makeRepository()
        let messages = sampleMessages()
        try repository.saveMessages(messages)

        try repository.saveMessages(messages.filter { $0.id != messages[1].id })

        let stored = try repository.fetchMessages()
        XCTAssertEqual(stored.count, 1)
        XCTAssertEqual(stored[0].id, messages[0].id)
    }

    func testStoreSurvivesRecreationOfTheRepository() throws {
        let original = sampleMessages()
        try makeRepository().saveMessages(original)

        // A brand new repository instance (as after an app relaunch) must see
        // exactly the same library.
        let reloaded = try SharedFileMessageRepository(storageURL: storageURL).fetchMessages()

        XCTAssertEqual(reloaded, original)
    }

    func testSaveCreatesIntermediateDirectoriesAutomatically() throws {
        let nestedURL = directory!
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent(WhisperStorageConfiguration.fileName)

        let repository = SharedFileMessageRepository(storageURL: nestedURL)
        try repository.saveMessages(sampleMessages())

        XCTAssertEqual(try repository.fetchMessages().count, 2)
    }

    // MARK: - Failure handling

    func testDamagedFileThrowsInsteadOfLosingDataSilently() throws {
        try Data("{\"not\": \"a message list\"".utf8).write(to: storageURL)

        XCTAssertThrowsError(try makeRepository().fetchMessages()) { error in
            guard let storeError = error as? MessageStoreError else {
                return XCTFail("Expected MessageStoreError, got \(error)")
            }
            if case .decodeFailed = storeError {
                // Expected.
            } else {
                XCTFail("Expected decodeFailed, got \(storeError)")
            }
        }
    }

    func testMissingFileIsNotAnError() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: storageURL.path))
        XCTAssertEqual(try makeRepository().fetchMessages(), [])
    }

    func testStorageLocationFallsBackWhenAppGroupIsUnavailable() {
        let url = SharedStorageURLFactory.makeStorageURL()

        XCTAssertEqual(url.lastPathComponent, WhisperStorageConfiguration.fileName)
    }
}
