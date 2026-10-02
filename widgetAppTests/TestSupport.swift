import Foundation
@testable import widgetApp

/// Deterministic calendar/clock fixtures shared by the test suite.
///
/// Everything is pinned to a gregorian calendar in GMT so scheduling tests do
/// not depend on the machine's time zone or on the current date.
enum TestClock {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    /// Builds a date in GMT. 2026-01-05 is a Monday, which keeps weekday
    /// expectations easy to reason about.
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        guard let date = calendar.date(from: components) else {
            preconditionFailure("Invalid test date \(year)-\(month)-\(day) \(hour):\(minute)")
        }
        return date
    }

    static func resolver() -> MessageScheduleResolver {
        MessageScheduleResolver(calendar: calendar)
    }

    /// A date whose ISO-8601 encoding is lossless (no sub-second component).
    static func storageSafeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        date(year, month, day, hour, minute)
    }

    static var iso8601JSONDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static var iso8601JSONEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

/// In-memory store used to exercise everything above the persistence layer.
final class InMemoryMessageRepository: MessageRepository {
    private(set) var stored: [Message]
    private(set) var saveCount = 0
    var errorToThrow: Error?

    init(seed: [Message] = []) {
        self.stored = seed
    }

    func fetchMessages() throws -> [Message] {
        if let errorToThrow { throw errorToThrow }
        return stored
    }

    func saveMessages(_ messages: [Message]) throws {
        if let errorToThrow { throw errorToThrow }
        stored = messages
        saveCount += 1
    }
}

/// Repository that always fails, used to verify error surfacing.
final class FailingMessageRepository: MessageRepository {
    struct Failure: LocalizedError {
        var errorDescription: String? { "Storage is unavailable." }
    }

    func fetchMessages() throws -> [Message] {
        throw Failure()
    }

    func saveMessages(_ messages: [Message]) throws {
        throw Failure()
    }
}

/// Records widget refresh requests instead of talking to WidgetKit.
final class RecordingWidgetReloader: WidgetReloading {
    private(set) var reloadCount = 0

    func reloadAllTimelines() {
        reloadCount += 1
    }
}
