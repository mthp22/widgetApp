import Foundation

/// A resolved schedule point for a specific message.
struct ScheduledMessage: Equatable {
    let message: Message
    let fireDate: Date
}

/// The message that should be rendered at a point in time.
///
/// - ``Phase/active``: the message has already reached its occurrence, so it is
///   the message currently in effect.
/// - ``Phase/upcoming``: nothing is in effect yet, so the earliest scheduled
///   message is previewed together with the date it will start.
struct MessageDisplay: Equatable {
    enum Phase: Equatable {
        case active
        case upcoming
    }

    let message: Message
    let phase: Phase
    let effectiveDate: Date
}

/// Scheduling rules for messages. Deliberately free of SwiftUI so the logic can
/// be unit tested with deterministic clocks.
protocol MessageScheduleResolving {
    /// The next occurrence of `message` at or after `referenceDate`, or `nil`
    /// when the message can never occur again (expired one-time message,
    /// empty content, invalid repeat days).
    func scheduledDate(for message: Message, after referenceDate: Date) -> Date?

    /// The message with the earliest upcoming occurrence after `referenceDate`.
    func nextScheduledMessage(from messages: [Message], after referenceDate: Date) -> ScheduledMessage?

    /// The message that should be displayed at `referenceDate`.
    func currentDisplay(at referenceDate: Date, in messages: [Message]) -> MessageDisplay?

    /// Future dates on which ``currentDisplay(at:in:)`` changes value, ordered
    /// ascending and bounded by `limit` entries and `horizon` seconds.
    func transitionDates(
        after referenceDate: Date,
        in messages: [Message],
        limit: Int,
        horizon: TimeInterval
    ) -> [Date]
}

struct MessageScheduleResolver: MessageScheduleResolving {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: Next occurrence

    func scheduledDate(for message: Message, after referenceDate: Date) -> Date? {
        guard message.isDisplayable else { return nil }

        let days = RepeatDay.normalized(message.repeatDays)

        if days.isEmpty {
            return nonRepeatingDate(for: message, after: referenceDate)
        }

        return nextRepeatingDate(for: message, days: days, after: referenceDate)
    }

    func nextScheduledMessage(from messages: [Message], after referenceDate: Date) -> ScheduledMessage? {
        messages
            .compactMap { message -> ScheduledMessage? in
                guard let fireDate = scheduledDate(for: message, after: referenceDate) else {
                    return nil
                }
                return ScheduledMessage(message: message, fireDate: fireDate)
            }
            .min { lhs, rhs in
                if lhs.fireDate == rhs.fireDate {
                    return lhs.message.id.uuidString < rhs.message.id.uuidString
                }
                return lhs.fireDate < rhs.fireDate
            }
    }

    // MARK: Current display

    func currentDisplay(at referenceDate: Date, in messages: [Message]) -> MessageDisplay? {
        if let active = mostRecentActiveMessage(at: referenceDate, in: messages) {
            return active
        }

        guard let upcoming = nextScheduledMessage(from: messages, after: referenceDate) else {
            return nil
        }

        return MessageDisplay(
            message: upcoming.message,
            phase: .upcoming,
            effectiveDate: upcoming.fireDate
        )
    }

    func transitionDates(
        after referenceDate: Date,
        in messages: [Message],
        limit: Int,
        horizon: TimeInterval
    ) -> [Date] {
        guard limit > 0 else { return [] }

        let deadline = referenceDate.addingTimeInterval(horizon)
        var cursor = referenceDate
        var latestDisplay = currentDisplay(at: referenceDate, in: messages)
        var transitions: [Date] = []

        while transitions.count < limit {
            let candidates = messages.compactMap { strictlyNextFireDate(for: $0, after: cursor) }
            guard let next = candidates.min(), next <= deadline else {
                break
            }

            if let display = currentDisplay(at: next, in: messages), !display.hasSameContent(as: latestDisplay) {
                transitions.append(next)
                latestDisplay = display
            }

            cursor = next
        }

        return transitions
    }

    // MARK: - Helpers

    private func nonRepeatingDate(for message: Message, after referenceDate: Date) -> Date? {
        guard let scheduledDate = message.scheduledDate else {
            // No date and no repeat days: the message is in effect immediately.
            return referenceDate
        }
        return scheduledDate >= referenceDate ? scheduledDate : nil
    }

    private func nextRepeatingDate(
        for message: Message,
        days: Set<Int>,
        after referenceDate: Date
    ) -> Date? {
        let time = occurrenceTime(for: message, fallback: referenceDate)
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let anchor = message.scheduledDate ?? .distantPast

        for offset in 0...14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                continue
            }

            guard days.contains(RepeatDay.from(date: day, calendar: calendar).rawValue) else {
                continue
            }

            guard let candidate = occurrenceDate(at: time, on: day),
                  candidate >= referenceDate,
                  candidate >= anchor else {
                continue
            }

            return candidate
        }

        return nil
    }

    /// The most recent occurrence at or before `referenceDate`, if any.
    ///
    /// One-time messages without a date count as having started in the distant
    /// past so that scheduled messages always take precedence over them.
    /// Repeating messages never report an occurrence before their anchor date,
    /// so a future schedule does not appear to be running early.
    private func mostRecentActiveMessage(
        at referenceDate: Date,
        in messages: [Message]
    ) -> MessageDisplay? {
        var winner: (message: Message, occurrence: Date)?

        for message in messages where message.isDisplayable {
            guard let occurrence = lastOccurrence(of: message, at: referenceDate) else { continue }

            guard let current = winner else {
                winner = (message, occurrence)
                continue
            }

            if occurrence > current.occurrence {
                winner = (message, occurrence)
            } else if occurrence == current.occurrence,
                      message.id.uuidString < current.message.id.uuidString {
                winner = (message, occurrence)
            }
        }

        guard let winner else { return nil }

        return MessageDisplay(
            message: winner.message,
            phase: .active,
            effectiveDate: winner.occurrence
        )
    }

    private func lastOccurrence(of message: Message, at referenceDate: Date) -> Date? {
        let days = RepeatDay.normalized(message.repeatDays)

        guard !days.isEmpty else {
            guard let scheduledDate = message.scheduledDate else {
                return .distantPast
            }
            return scheduledDate <= referenceDate ? scheduledDate : nil
        }

        let time = occurrenceTime(for: message, fallback: referenceDate)
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let anchor = message.scheduledDate ?? .distantPast

        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else {
                continue
            }

            guard days.contains(RepeatDay.from(date: day, calendar: calendar).rawValue) else {
                continue
            }

            guard let candidate = occurrenceDate(at: time, on: day),
                  candidate <= referenceDate,
                  candidate >= anchor else {
                continue
            }

            return candidate
        }

        return nil
    }

    private func strictlyNextFireDate(for message: Message, after referenceDate: Date) -> Date? {
        guard let fireDate = scheduledDate(for: message, after: referenceDate),
              fireDate > referenceDate else {
            return nil
        }
        return fireDate
    }

    private func occurrenceTime(for message: Message, fallback: Date) -> DateComponents {
        calendar.dateComponents(
            [.hour, .minute, .second],
            from: message.scheduledDate ?? fallback
        )
    }

    private func occurrenceDate(at time: DateComponents, on day: Date) -> Date? {
        calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: time.second ?? 0,
            of: day
        )
    }
}

private extension MessageDisplay {
    /// Whether two displays would render the same content to the user.
    func hasSameContent(as other: MessageDisplay?) -> Bool {
        guard let other else { return false }
        return message.id == other.message.id && phase == other.phase
    }
}
