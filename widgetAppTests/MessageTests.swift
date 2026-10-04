import Foundation
import XCTest
@testable import widgetApp

final class MessageTests: XCTestCase {
    // MARK: - Identity and normalization

    func testMessageKeepsStableIdentityAndTrimsContent() {
        let message = Message(
            content: "  Rise and shine  ",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .bold
        )

        XCTAssertEqual(message.normalizedContent, "Rise and shine")
        XCTAssertEqual(message.content, "  Rise and shine  ")
        XCTAssertTrue(message.isDisplayable)
    }

    func testEmptyRepeatDaysAreNormalizedToNil() {
        let message = Message(content: "Hello", scheduledDate: nil, repeatDays: [], widgetStyle: .casual)

        XCTAssertNil(message.repeatDays)
        XCTAssertFalse(message.hasRepeatingSchedule)
    }

    func testInvalidRepeatDaysAreDropped() {
        let message = Message(
            content: "Hello",
            scheduledDate: nil,
            repeatDays: [0, 1, 4, 8, 9],
            widgetStyle: .formal
        )

        XCTAssertEqual(message.repeatDays, [1, 4])
        XCTAssertEqual(message.sortedRepeatDays.map(\.rawValue), [1, 4])
    }

    func testEqualityIsPredictable() {
        let id = UUID()
        let first = Message(id: id, content: "Same", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let second = Message(id: id, content: "Same", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let third = Message(id: UUID(), content: "Same", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, third)
    }

    // MARK: - Codable

    func testCodableRoundTripPreservesEveryField() throws {
        let original = Message(
            content: "Standup at 09:00",
            scheduledDate: TestClock.storageSafeDate(2026, 3, 2, 9, 0),
            repeatDays: [2, 4, 6],
            widgetStyle: .formal
        )

        let data = try TestClock.iso8601JSONEncoder.encode([original])
        let decoded = try TestClock.iso8601JSONDecoder.decode([Message].self, from: data)

        XCTAssertEqual(decoded, [original])
        XCTAssertEqual(decoded.first?.widgetStyle, .formal)
        XCTAssertEqual(decoded.first?.repeatDays, [2, 4, 6])
    }

    func testDecodingMissingScheduleFieldsStillSucceeds() throws {
        let json = """
        {"id":"6F1C4A20-8B43-4E6B-9A0B-2F7A1C9D1111","content":"Only text","widgetStyle":"bold"}
        """

        let decoded = try TestClock.iso8601JSONDecoder.decode(Message.self, from: Data(json.utf8))

        XCTAssertNil(decoded.scheduledDate)
        XCTAssertNil(decoded.repeatDays)
        XCTAssertEqual(decoded.content, "Only text")
    }

    func testDecodingDamagedPayloadThrows() {
        let json = """
        {"id":"not-a-uuid","content":"Broken","widgetStyle":"bold"}
        """

        XCTAssertThrowsError(
            try TestClock.iso8601JSONDecoder.decode(Message.self, from: Data(json.utf8))
        )
    }

    // MARK: - Styles

    func testAllStylesAreRepresented() {
        XCTAssertEqual(MessageStyle.allCases, [.bold, .casual, .formal])
        XCTAssertEqual(MessageStyle.bold.title, "Bold")
        XCTAssertTrue(MessageStyle.allCases.allSatisfy { !$0.foregroundHex.isEmpty })
    }

    func testStylesRoundTripThroughCodable() throws {
        for style in MessageStyle.allCases {
            let data = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(MessageStyle.self, from: data)
            XCTAssertEqual(decoded, style)
        }
    }
}

final class RepeatDayTests: XCTestCase {
    func testRawValuesFollowMondayBasedNumbering() {
        XCTAssertEqual(RepeatDay.monday.rawValue, 1)
        XCTAssertEqual(RepeatDay.tuesday.rawValue, 2)
        XCTAssertEqual(RepeatDay.wednesday.rawValue, 3)
        XCTAssertEqual(RepeatDay.thursday.rawValue, 4)
        XCTAssertEqual(RepeatDay.friday.rawValue, 5)
        XCTAssertEqual(RepeatDay.saturday.rawValue, 6)
        XCTAssertEqual(RepeatDay.sunday.rawValue, 7)
        XCTAssertEqual(RepeatDay.allCases.count, 7)
    }

    func testCalendarWeekdayConversion() {
        // Calendar uses 1 = Sunday … 7 = Saturday.
        XCTAssertEqual(RepeatDay.sunday.calendarWeekdayValue, 1)
        XCTAssertEqual(RepeatDay.monday.calendarWeekdayValue, 2)
        XCTAssertEqual(RepeatDay.saturday.calendarWeekdayValue, 7)
    }

    func testMapsEveryDateToItsDay() {
        // 2026-01-04 is a Sunday, 2026-01-05 a Monday, 2026-01-10 a Saturday.
        XCTAssertEqual(RepeatDay.from(date: TestClock.date(2026, 1, 4), calendar: TestClock.calendar), .sunday)
        XCTAssertEqual(RepeatDay.from(date: TestClock.date(2026, 1, 5), calendar: TestClock.calendar), .monday)
        XCTAssertEqual(RepeatDay.from(date: TestClock.date(2026, 1, 10), calendar: TestClock.calendar), .saturday)
    }

    func testNormalizedDropsOutOfRangeValues() {
        XCTAssertEqual(RepeatDay.normalized(nil), [])
        XCTAssertEqual(RepeatDay.normalized([-3, 1, 7, 12]), [1, 7])
    }

    func testShortNamesAreFormattedInWeekOrder() {
        XCTAssertEqual(RepeatDay.shortNames(for: [5, 1, 3]), "Mon, Wed, Fri")
        XCTAssertEqual(RepeatDay.shortNames(for: []), "")
    }
}
