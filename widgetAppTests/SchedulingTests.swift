import Foundation
import XCTest
@testable import widgetApp

final class SchedulingTests: XCTestCase {
    private let resolver = TestClock.resolver()

    // MARK: - One-time messages

    func testFutureOneTimeMessageReturnsItsScheduledDate() {
        let reference = TestClock.date(2026, 1, 5, 10, 0)
        let scheduled = TestClock.date(2026, 1, 5, 11, 15)
        let message = Message(content: "Standup reminder", scheduledDate: scheduled, repeatDays: nil, widgetStyle: .bold)

        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), scheduled)
    }

    func testExpiredOneTimeMessageIsNotScheduledAgain() {
        let reference = TestClock.date(2026, 1, 5, 12, 0)
        let scheduled = TestClock.date(2026, 1, 5, 10, 0)
        let message = Message(content: "Past reminder", scheduledDate: scheduled, repeatDays: nil, widgetStyle: .formal)

        XCTAssertNil(resolver.scheduledDate(for: message, after: reference))
    }

    func testTodaysScheduledMessageIsReturnedForLaterToday() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let scheduled = TestClock.date(2026, 1, 5, 20, 30)
        let message = Message(content: "Evening note", scheduledDate: scheduled, repeatDays: nil, widgetStyle: .casual)

        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), scheduled)
    }

    func testMessageWithoutDateAppliesImmediately() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let message = Message(content: "Always on", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)

        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), reference)
    }

    func testEmptyContentIsNeverScheduled() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let message = Message(content: "   ", scheduledDate: reference, repeatDays: nil, widgetStyle: .bold)

        XCTAssertNil(resolver.scheduledDate(for: message, after: reference))
    }

    // MARK: - Repeating messages

    func testRepeatingMessageResolvesToNextMatchingDayAndTime() {
        let reference = TestClock.date(2026, 1, 6, 9, 0) // Tuesday
        let message = Message(
            content: "Gym",
            scheduledDate: TestClock.date(2026, 1, 6, 8, 30),
            repeatDays: [RepeatDay.wednesday.rawValue, RepeatDay.friday.rawValue],
            widgetStyle: .casual
        )

        // Next Wednesday at 08:30.
        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), TestClock.date(2026, 1, 7, 8, 30))
    }

    func testRepeatingMessageLaterTodayIsScheduledForLaterToday() {
        let reference = TestClock.date(2026, 1, 5, 7, 0) // Monday 07:00
        let message = Message(
            content: "Morning pages",
            scheduledDate: TestClock.date(2026, 1, 5, 8, 0),
            repeatDays: [RepeatDay.monday.rawValue],
            widgetStyle: .bold
        )

        // Today's occurrence has not happened yet.
        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), TestClock.date(2026, 1, 5, 8, 0))
    }

    func testRepeatingMessageTodayAfterItsTimeRollsToNextWeek() {
        let reference = TestClock.date(2026, 1, 5, 9, 0) // Monday 09:00, after 08:00
        let message = Message(
            content: "Morning pages",
            scheduledDate: TestClock.date(2026, 1, 5, 8, 0),
            repeatDays: [RepeatDay.monday.rawValue],
            widgetStyle: .bold
        )

        // Next Monday, crossing the week boundary.
        XCTAssertEqual(resolver.scheduledDate(for: message, after: reference), TestClock.date(2026, 1, 12, 8, 0))
    }

    func testEveryWeekdayResolvesToThatWeekdayAtTheConfiguredTime() {
        for day in RepeatDay.allCases {
            let reference = TestClock.date(2026, 1, 5, 9, 0) // Monday morning
            let message = Message(
                content: day.fullName,
                scheduledDate: TestClock.date(2026, 1, 5, 18, 45),
                repeatDays: [day.rawValue],
                widgetStyle: .formal
            )

            guard let next = resolver.scheduledDate(for: message, after: reference) else {
                return XCTFail("Expected an occurrence for \(day.fullName)")
            }

            XCTAssertGreaterThan(next, reference, "\(day.fullName) must be in the future")
            XCTAssertEqual(
                RepeatDay.from(date: next, calendar: TestClock.calendar),
                day,
                "\(day.fullName) must land on its own weekday"
            )

            let time = TestClock.calendar.dateComponents([.hour, .minute], from: next)
            XCTAssertEqual(time.hour, 18)
            XCTAssertEqual(time.minute, 45)
        }
    }

    // MARK: - Next scheduled message

    func testNextScheduledMessagePicksTheEarliestOccurrence() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let later = Message(content: "Later", scheduledDate: TestClock.date(2026, 1, 7, 8, 0), repeatDays: nil, widgetStyle: .bold)
        let sooner = Message(content: "Sooner", scheduledDate: TestClock.date(2026, 1, 6, 8, 0), repeatDays: nil, widgetStyle: .casual)

        let next = resolver.nextScheduledMessage(from: [later, sooner], after: reference)

        XCTAssertEqual(next?.message.content, "Sooner")
        XCTAssertEqual(next?.fireDate, TestClock.date(2026, 1, 6, 8, 0))
    }

    func testNextScheduledMessageReturnsNilWhenNothingMatches() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)

        XCTAssertNil(resolver.nextScheduledMessage(from: [], after: reference))

        let expired = Message(content: "Gone", scheduledDate: TestClock.date(2026, 1, 1, 8, 0), repeatDays: nil, widgetStyle: .bold)
        XCTAssertNil(resolver.nextScheduledMessage(from: [expired], after: reference))
    }

    // MARK: - Current display

    func testFutureMessageIsShownAsUpcoming() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let scheduled = TestClock.date(2026, 1, 5, 18, 0)
        let message = Message(content: "Tonight", scheduledDate: scheduled, repeatDays: nil, widgetStyle: .bold)

        let display = resolver.currentDisplay(at: reference, in: [message])

        XCTAssertEqual(display?.phase, .upcoming)
        XCTAssertEqual(display?.effectiveDate, scheduled)
        XCTAssertEqual(display?.message.id, message.id)
    }

    func testStartedOneTimeMessageIsActive() {
        let reference = TestClock.date(2026, 1, 5, 12, 0)
        let started = TestClock.date(2026, 1, 5, 9, 0)
        let message = Message(content: "Good afternoon", scheduledDate: started, repeatDays: nil, widgetStyle: .casual)

        let display = resolver.currentDisplay(at: reference, in: [message])

        XCTAssertEqual(display?.phase, .active)
        XCTAssertEqual(display?.effectiveDate, started)
    }

    func testMostRecentlyStartedMessageWins() {
        let older = Message(content: "Older", scheduledDate: TestClock.date(2026, 1, 4, 9, 0), repeatDays: nil, widgetStyle: .bold)
        let newer = Message(content: "Newer", scheduledDate: TestClock.date(2026, 1, 5, 9, 0), repeatDays: nil, widgetStyle: .formal)

        let display = resolver.currentDisplay(at: TestClock.date(2026, 1, 5, 12, 0), in: [older, newer])

        XCTAssertEqual(display?.message.content, "Newer")
        XCTAssertEqual(display?.phase, .active)
    }

    func testImmediateMessageLosesToAnyStartedMessage() {
        let immediate = Message(content: "Immediate", scheduledDate: nil, repeatDays: nil, widgetStyle: .bold)
        let started = Message(content: "Started", scheduledDate: TestClock.date(2026, 1, 5, 9, 0), repeatDays: nil, widgetStyle: .casual)

        let display = resolver.currentDisplay(at: TestClock.date(2026, 1, 5, 12, 0), in: [immediate, started])

        XCTAssertEqual(display?.message.content, "Started")
    }

    func testRepeatingMessageIsActiveOnItsDayAfterTheConfiguredTime() {
        let message = Message(
            content: "Wednesday note",
            scheduledDate: TestClock.date(2026, 1, 4, 10, 0),
            repeatDays: [RepeatDay.wednesday.rawValue],
            widgetStyle: .formal
        )

        let before = resolver.currentDisplay(at: TestClock.date(2026, 1, 7, 9, 59), in: [message])
        let after = resolver.currentDisplay(at: TestClock.date(2026, 1, 7, 10, 0), in: [message])

        // Before today's occurrence the schedule has not started yet.
        XCTAssertEqual(before?.phase, .upcoming)
        XCTAssertEqual(before?.effectiveDate, TestClock.date(2026, 1, 7, 10, 0))
        XCTAssertEqual(after?.phase, .active)
        XCTAssertEqual(after?.effectiveDate, TestClock.date(2026, 1, 7, 10, 0))
    }

    func testRepeatingMessageIsNotActiveBeforeItsAnchorDate() {
        let message = Message(
            content: "Starts next week",
            scheduledDate: TestClock.date(2026, 1, 12, 9, 0), // Monday
            repeatDays: [RepeatDay.monday.rawValue],
            widgetStyle: .bold
        )

        let beforeAnchor = resolver.currentDisplay(at: TestClock.date(2026, 1, 6, 12, 0), in: [message])
        let atAnchor = resolver.currentDisplay(at: TestClock.date(2026, 1, 12, 9, 0), in: [message])

        XCTAssertEqual(beforeAnchor?.phase, .upcoming)
        XCTAssertEqual(beforeAnchor?.effectiveDate, TestClock.date(2026, 1, 12, 9, 0))
        XCTAssertEqual(atAnchor?.phase, .active)
    }

    func testDisplayIsEmptyWhenThereAreNoMessages() {
        XCTAssertNil(resolver.currentDisplay(at: TestClock.date(2026, 1, 5, 8, 0), in: []))
    }

    // MARK: - Transitions

    func testTransitionOccursWhenAnUpcomingMessageStarts() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let scheduled = TestClock.date(2026, 1, 5, 18, 0)
        let message = Message(content: "Tonight", scheduledDate: scheduled, repeatDays: nil, widgetStyle: .bold)

        let transitions = resolver.transitionDates(after: reference, in: [message], limit: 5, horizon: 7 * 24 * 3600)

        XCTAssertEqual(transitions, [scheduled])
    }

    func testTransitionsAreOrderedAndLimited() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let messages = [
            Message(content: "A", scheduledDate: TestClock.date(2026, 1, 6, 9, 0), repeatDays: nil, widgetStyle: .bold),
            Message(content: "B", scheduledDate: TestClock.date(2026, 1, 7, 9, 0), repeatDays: nil, widgetStyle: .casual),
            Message(content: "C", scheduledDate: TestClock.date(2026, 1, 8, 9, 0), repeatDays: nil, widgetStyle: .formal)
        ]

        let transitions = resolver.transitionDates(after: reference, in: messages, limit: 2, horizon: 30 * 24 * 3600)

        XCTAssertEqual(transitions, [TestClock.date(2026, 1, 6, 9, 0), TestClock.date(2026, 1, 7, 9, 0)])
    }

    func testTransitionsIgnoreTimesBeyondTheHorizon() {
        let reference = TestClock.date(2026, 1, 5, 8, 0)
        let message = Message(content: "Far away", scheduledDate: TestClock.date(2026, 6, 1, 9, 0), repeatDays: nil, widgetStyle: .bold)

        let transitions = resolver.transitionDates(after: reference, in: [message], limit: 5, horizon: 24 * 3600)

        XCTAssertTrue(transitions.isEmpty)
    }

    func testRepeatingMessageProducesDailyTransitions() {
        let reference = TestClock.date(2026, 1, 5, 7, 0)
        let message = Message(
            content: "Daily",
            scheduledDate: TestClock.date(2026, 1, 5, 8, 0),
            repeatDays: [RepeatDay.monday.rawValue, RepeatDay.tuesday.rawValue, RepeatDay.wednesday.rawValue],
            widgetStyle: .bold
        )

        let transitions = resolver.transitionDates(after: reference, in: [message], limit: 5, horizon: 7 * 24 * 3600)

        XCTAssertEqual(transitions.first, TestClock.date(2026, 1, 5, 8, 0))
        XCTAssertTrue(transitions.allSatisfy { $0 > reference })
    }
}
