import XCTest
@testable import widgetApp

final class MessageScheduleResolverTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testNonRepeatingFutureMessageReturnsItsScheduledDate() {
        let resolver = MessageScheduleResolver(calendar: calendar)
        let reference = makeDate(year: 2026, month: 1, day: 5, hour: 10, minute: 0)
        let scheduled = makeDate(year: 2026, month: 1, day: 5, hour: 11, minute: 15)

        let message = Message(
            content: "Standup reminder",
            scheduledDate: scheduled,
            repeatDays: nil,
            widgetStyle: .bold
        )

        let result = resolver.scheduledDate(for: message, after: reference)
        XCTAssertEqual(result, scheduled)
    }

    func testPastOneTimeMessageIsIgnored() {
        let resolver = MessageScheduleResolver(calendar: calendar)
        let reference = makeDate(year: 2026, month: 1, day: 5, hour: 12, minute: 0)
        let scheduled = makeDate(year: 2026, month: 1, day: 5, hour: 10, minute: 0)

        let message = Message(
            content: "Past reminder",
            scheduledDate: scheduled,
            repeatDays: nil,
            widgetStyle: .formal
        )

        XCTAssertNil(resolver.scheduledDate(for: message, after: reference))
    }

    func testRepeatingMessageResolvesToNextMatchingDayAndTime() {
        let resolver = MessageScheduleResolver(calendar: calendar)
        let reference = makeDate(year: 2026, month: 1, day: 6, hour: 9, minute: 0)
        let scheduleTime = makeDate(year: 2026, month: 1, day: 6, hour: 8, minute: 30)

        let message = Message(
            content: "Gym",
            scheduledDate: scheduleTime,
            repeatDays: [Weekday.wednesday.rawValue, Weekday.friday.rawValue],
            widgetStyle: .casual
        )

        let nextDate = resolver.scheduledDate(for: message, after: reference)
        let expected = makeDate(year: 2026, month: 1, day: 7, hour: 8, minute: 30)
        XCTAssertEqual(nextDate, expected)
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }
}

final class MessageManagerTests: XCTestCase {
    func testCreateMessagePersistsAndTrimsContent() throws {
        let repository = InMemoryRepository()
        let resolver = MessageScheduleResolver(calendar: .current)
        let reloader = ReloadingSpy()

        let manager = MessageManager(
            repository: repository,
            resolver: resolver,
            widgetReloader: reloader,
            backgroundChecksEnabled: false
        )

        try manager.createMessage(
            content: "  Focus block  ",
            scheduledDate: nil,
            repeatDays: nil,
            style: .bold
        )

        XCTAssertEqual(manager.messages.count, 1)
        XCTAssertEqual(manager.messages.first?.content, "Focus block")
        XCTAssertEqual(repository.savedBatches.count, 1)
        XCTAssertGreaterThanOrEqual(reloader.reloadCount, 1)
    }

    func testUpdateMessageChangesPersistedValue() throws {
        let id = UUID()
        let existing = Message(
            id: id,
            content: "Old",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .formal
        )

        let repository = InMemoryRepository(seed: [existing])
        let manager = MessageManager(
            repository: repository,
            resolver: MessageScheduleResolver(),
            widgetReloader: ReloadingSpy(),
            backgroundChecksEnabled: false
        )

        let updated = Message(
            id: id,
            content: "New",
            scheduledDate: existing.scheduledDate,
            repeatDays: existing.repeatDays,
            widgetStyle: .casual
        )

        try manager.updateMessage(updated)

        XCTAssertEqual(manager.messages.first?.content, "New")
        XCTAssertEqual(manager.messages.first?.widgetStyle, .casual)
    }

    func testDeleteMessageRemovesEntry() throws {
        let message = Message(content: "Delete me", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let repository = InMemoryRepository(seed: [message])

        let manager = MessageManager(
            repository: repository,
            resolver: MessageScheduleResolver(),
            widgetReloader: ReloadingSpy(),
            backgroundChecksEnabled: false
        )

        try manager.deleteMessage(id: message.id)
        XCTAssertTrue(manager.messages.isEmpty)
    }
}

private final class InMemoryRepository: MessageRepository {
    private(set) var data: [Message]
    private(set) var savedBatches: [[Message]] = []

    init(seed: [Message] = []) {
        self.data = seed
    }

    func fetchMessages() throws -> [Message] {
        data
    }

    func saveMessages(_ messages: [Message]) throws {
        data = messages
        savedBatches.append(messages)
    }
}

private final class ReloadingSpy: WidgetReloading {
    private(set) var reloadCount = 0

    func reloadAllTimelines() {
        reloadCount += 1
    }
}
