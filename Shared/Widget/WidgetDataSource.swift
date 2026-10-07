import Foundation
import WidgetKit
import os

/// Builds widget content from the persisted message library.
///
/// This is the single data path used by the WidgetKit timeline provider: it
/// reads the shared store, asks the schedule resolver what should be visible
/// and turns the answer into timeline entries plus a reload policy.
///
/// It lives in `Shared` (rather than only in the extension) so the widget data
/// flow is covered by unit tests in the application test target.
struct WidgetDataSource {
    /// How many entries a single timeline contains (current state + upcoming changes).
    static let defaultEntryLimit = 8
    /// How far ahead transitions are pre-computed (7 days).
    static let defaultHorizon: TimeInterval = 7 * 24 * 60 * 60
    /// Hard ceiling on the reload delay: the timeline is regenerated at least
    /// this often so widget content is re-evaluated automatically every
    /// 15 minutes even when nothing is scheduled.
    static let periodicRefreshInterval: TimeInterval = 15 * 60
    /// Reload delay when the stored data cannot be read.
    static let retryRefreshInterval: TimeInterval = 15 * 60

    private let repository: MessageRepository
    private let resolver: MessageScheduleResolving
    private let entryLimit: Int
    private let horizon: TimeInterval

    private static let logger = Logger(
        subsystem: WhisperStorageConfiguration.appGroupIdentifier,
        category: "WidgetDataSource"
    )

    init(
        repository: MessageRepository = SharedFileMessageRepository(),
        resolver: MessageScheduleResolving = MessageScheduleResolver(),
        entryLimit: Int = WidgetDataSource.defaultEntryLimit,
        horizon: TimeInterval = WidgetDataSource.defaultHorizon
    ) {
        self.repository = repository
        self.resolver = resolver
        self.entryLimit = max(1, entryLimit)
        self.horizon = horizon
    }

    /// A timeline describing what to render from `now` onwards.
    func timeline(from now: Date) -> WidgetTimeline {
        let messages: [Message]
        do {
            messages = try repository.fetchMessages()
        } catch {
            Self.logger.error(
                "Reading the shared message library failed: \(error.localizedDescription, privacy: .public)"
            )
            return WidgetTimeline(
                entries: [WhisperWidgetEntry.unavailable(at: now)],
                policy: .after(now.addingTimeInterval(Self.retryRefreshInterval))
            )
        }

        return Self.timeline(for: messages, from: now, resolver: resolver, entryLimit: entryLimit, horizon: horizon)
    }

    /// The single entry that should be visible right now.
    func currentEntry(at now: Date) -> WhisperWidgetEntry {
        do {
            let messages = try repository.fetchMessages()
            return Self.entry(for: messages, at: now, resolver: resolver)
        } catch {
            Self.logger.error(
                "Reading the shared message library failed: \(error.localizedDescription, privacy: .public)"
            )
            return .unavailable(at: now)
        }
    }

    // MARK: - Pure timeline construction (unit tested)

    static func timeline(
        for messages: [Message],
        from now: Date,
        resolver: MessageScheduleResolving,
        entryLimit: Int = defaultEntryLimit,
        horizon: TimeInterval = defaultHorizon
    ) -> WidgetTimeline {
        var entries: [WhisperWidgetEntry] = [entry(for: messages, at: now, resolver: resolver)]

        let transitions = resolver.transitionDates(
            after: now,
            in: messages,
            limit: max(0, entryLimit - 1),
            horizon: horizon
        )

        entries.reserveCapacity(entries.count + transitions.count)
        for transition in transitions {
            entries.append(entry(for: messages, at: transition, resolver: resolver))
        }

        // A scheduled transition can come sooner than the periodic ceiling, in
        // which case the transition drives the reload; otherwise the timeline
        // still refreshes automatically every `periodicRefreshInterval`.
        let nextTransition = transitions.first ?? Date.distantFuture
        let refreshDate = min(nextTransition, now.addingTimeInterval(Self.periodicRefreshInterval))
        return WidgetTimeline(entries: entries, policy: .after(refreshDate))
    }

    static func entry(
        for messages: [Message],
        at date: Date,
        resolver: MessageScheduleResolving
    ) -> WhisperWidgetEntry {
        guard let display = resolver.currentDisplay(at: date, in: messages) else {
            return .empty(at: date)
        }

        return WhisperWidgetEntry(
            date: date,
            content: .message(
                display.message,
                phase: display.phase,
                effectiveAt: display.effectiveDate
            )
        )
    }
}

/// A generated widget timeline: the entries to render and when to reload.
struct WidgetTimeline {
    let entries: [WhisperWidgetEntry]
    let policy: TimelineReloadPolicy
}
