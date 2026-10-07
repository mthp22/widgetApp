import Foundation
import XCTest
import WidgetKit
@testable import widgetApp

/// Covers the data path the widget actually uses: shared store → resolver →
/// timeline entries and reload policy.
final class WidgetTimelineTests: XCTestCase {
    private let now = TestClock.date(2026, 1, 5, 8, 0)
    private let resolver = TestClock.resolver()

    // MARK: - Empty and unavailable states

    func testEmptyLibraryProducesASingleEmptyEntry() {
        let timeline = WidgetDataSource.timeline(for: [], from: now, resolver: resolver)

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(timeline.entries.first?.content, .empty)
        XCTAssertEqual(timeline.entries.first?.date, now)
        XCTAssertEqual(
            timeline.policy,
            .after(now.addingTimeInterval(WidgetDataSource.periodicRefreshInterval))
        )
    }

    /// Nothing is scheduled far ahead, so the periodic ceiling decides when the
    /// widget reloads — guaranteeing the automatic 15-minute refresh.
    func testReloadIsCappedAtThePeriodicIntervalWhenNothingIsScheduled() {
        let timeline = WidgetDataSource.timeline(for: [], from: now, resolver: resolver)

        XCTAssertEqual(
            timeline.policy,
            .after(now.addingTimeInterval(WidgetDataSource.periodicRefreshInterval))
        )
    }

    /// A transition inside the 15-minute window still drives the reload, so an
    /// imminent message never waits for the periodic refresh.
    func testImminentTransitionDrivesTheReloadBeforeThePeriodicCeiling() {
        let fireDate = TestClock.date(2026, 1, 5, 8, 5)
        let message = Message(
            content: "Soon",
            scheduledDate: fireDate,
            repeatDays: nil,
            widgetStyle: .bold
        )

        let timeline = WidgetDataSource.timeline(for: [message], from: now, resolver: resolver)

        XCTAssertEqual(timeline.policy, .after(fireDate))
    }

    func testDamagedStoreProducesAnUnavailableEntry() {
        let repository = InMemoryMessageRepository()
        repository.errorToThrow = MessageStoreError.decodeFailed(
            url: URL(fileURLWithPath: "/tmp/whisper_messages.json"),
            underlying: NSError(domain: "WhisperWidgetTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Damaged file"])
        )

        let timeline = WidgetDataSource(repository: repository, resolver: resolver)
            .timeline(from: now)

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(timeline.entries.first?.content, .unavailable)
        XCTAssertEqual(
            timeline.policy,
            .after(now.addingTimeInterval(WidgetDataSource.retryRefreshInterval))
        )
    }

    func testCurrentEntryFallsBackToUnavailableWhenTheStoreCannotBeRead() {
        let repository = InMemoryMessageRepository()
        repository.errorToThrow = NSError(domain: "WhisperWidgetTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing file"])

        let entry = WidgetDataSource(repository: repository, resolver: resolver).currentEntry(at: now)

        XCTAssertEqual(entry.content, .unavailable)
        XCTAssertEqual(entry.compactText, "Messages unavailable")
    }

    // MARK: - Real content

    func testUpcomingMessageIsPreviewedThenStartsAtItsFireDate() {
        let fireDate = TestClock.date(2026, 1, 5, 18, 0)
        let message = Message(
            content: "Evening walk",
            scheduledDate: fireDate,
            repeatDays: nil,
            widgetStyle: .bold
        )

        let timeline = WidgetDataSource.timeline(for: [message], from: now, resolver: resolver)

        XCTAssertEqual(timeline.entries.count, 2)

        guard case let .message(preview, phase, effectiveAt) = timeline.entries[0].content else {
            return XCTFail("Expected a message entry, got \(timeline.entries[0].content)")
        }
        XCTAssertEqual(preview.content, "Evening walk")
        XCTAssertEqual(phase, .upcoming)
        XCTAssertEqual(effectiveAt, fireDate)
        XCTAssertTrue(timeline.entries[0].caption?.hasPrefix("Scheduled") == true)

        guard case let .message(active, activePhase, activeEffectiveAt) = timeline.entries[1].content else {
            return XCTFail("Expected a message entry at the transition")
        }
        XCTAssertEqual(active.id, message.id)
        XCTAssertEqual(activePhase, .active)
        XCTAssertEqual(activeEffectiveAt, fireDate)
        XCTAssertEqual(timeline.entries[1].date, fireDate)
        XCTAssertNil(timeline.entries[1].caption)

        // The fire date is covered by the pre-built entry, so the reload itself
        // is scheduled by the 15-minute periodic ceiling.
        XCTAssertEqual(
            timeline.policy,
            .after(now.addingTimeInterval(WidgetDataSource.periodicRefreshInterval))
        )
    }

    func testActiveMessageIsRenderedWithoutACaption() {
        let message = Message(
            content: "In effect",
            scheduledDate: TestClock.date(2026, 1, 5, 6, 0),
            repeatDays: nil,
            widgetStyle: .formal
        )

        let timeline = WidgetDataSource.timeline(for: [message], from: now, resolver: resolver)

        guard case let .message(rendered, phase, _) = timeline.entries[0].content else {
            return XCTFail("Expected a message entry")
        }
        XCTAssertEqual(rendered.content, "In effect")
        XCTAssertEqual(phase, .active)
        XCTAssertEqual(timeline.entries[0].compactText, "In effect")
        XCTAssertNil(timeline.entries[0].caption)
    }

    func testRepeatingMessageProducesOneEntryPerContentChange() {
        let message = Message(
            content: "Weekday standup",
            scheduledDate: TestClock.date(2026, 1, 5, 9, 0),
            repeatDays: [1, 2, 3, 4, 5],
            widgetStyle: .casual
        )

        let timeline = WidgetDataSource.timeline(for: [message], from: now, resolver: resolver)

        // Preview until 09:00, then active — the repeating content itself never
        // changes again, so no further entries are generated.
        XCTAssertEqual(timeline.entries.count, 2)
        XCTAssertEqual(
            timeline.policy,
            .after(now.addingTimeInterval(WidgetDataSource.periodicRefreshInterval))
        )
    }

    func testLongContentIsNotTruncatedInTheDataLayer() {
        let longText = Array(
            repeating: "A thoughtful message that keeps going.",
            count: 12
        ).joined(separator: " ")
        let message = Message(
            content: longText,
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .bold
        )

        let timeline = WidgetDataSource.timeline(for: [message], from: now, resolver: resolver)

        XCTAssertEqual(timeline.entries.first?.compactText, longText)
    }

    // MARK: - Store backed data source

    func testDataSourceReadsTheSharedStore() {
        let message = Message(
            content: "From the store",
            scheduledDate: nil,
            repeatDays: nil,
            widgetStyle: .bold
        )
        let repository = InMemoryMessageRepository(seed: [message])

        let entry = WidgetDataSource(repository: repository, resolver: resolver).currentEntry(at: now)

        guard case let .message(rendered, phase, _) = entry.content else {
            return XCTFail("Expected the stored message to be rendered")
        }
        XCTAssertEqual(rendered.id, message.id)
        XCTAssertEqual(phase, .active)
    }

    func testSnapshotAndTimelineAgreeForAnEmptyStore() {
        let repository = InMemoryMessageRepository()
        let dataSource = WidgetDataSource(repository: repository, resolver: resolver)

        let snapshot = dataSource.currentEntry(at: now)
        let timeline = dataSource.timeline(from: now)

        XCTAssertEqual(snapshot.content, .empty)
        XCTAssertEqual(timeline.entries.first, snapshot)
    }

    func testEntryLimitIsRespected() {
        let messages = (0..<10).map { index in
            Message(
                content: "Message \(index)",
                scheduledDate: TestClock.date(2026, 1, 5, 10 + index, 0),
                repeatDays: nil,
                widgetStyle: .bold
            )
        }

        let timeline = WidgetDataSource.timeline(
            for: messages,
            from: now,
            resolver: resolver,
            entryLimit: 3
        )

        XCTAssertEqual(timeline.entries.count, 3)
    }
}
