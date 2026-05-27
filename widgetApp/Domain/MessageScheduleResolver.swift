import Foundation

struct ScheduledMessage: Equatable {
    let message: Message
    let fireDate: Date
}

protocol MessageScheduleResolving {
    func nextScheduledMessage(from messages: [Message], after referenceDate: Date) -> ScheduledMessage?
    func scheduledDate(for message: Message, after referenceDate: Date) -> Date?
}

struct MessageScheduleResolver: MessageScheduleResolving {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func nextScheduledMessage(from messages: [Message], after referenceDate: Date) -> ScheduledMessage? {
        messages
            .compactMap { message in
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

    func scheduledDate(for message: Message, after referenceDate: Date) -> Date? {
        let content = message.normalizedContent
        guard !content.isEmpty else { return nil }

        let days = normalizedRepeatDays(message.repeatDays)

        if days.isEmpty {
            return nonRepeatingDate(for: message, after: referenceDate)
        }

        return nextRepeatingDate(for: message, days: days, after: referenceDate)
    }

    private func nonRepeatingDate(for message: Message, after referenceDate: Date) -> Date? {
        guard let scheduledDate = message.scheduledDate else {
            return referenceDate
        }
        return scheduledDate >= referenceDate ? scheduledDate : nil
    }

    private func nextRepeatingDate(for message: Message, days: Set<Int>, after referenceDate: Date) -> Date? {
        let baseTimeSource = message.scheduledDate ?? referenceDate
        let time = calendar.dateComponents([.hour, .minute, .second], from: baseTimeSource)
        let startOfToday = calendar.startOfDay(for: referenceDate)

        for offset in 0...14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) else {
                continue
            }

            let weekday = Weekday.from(date: day, calendar: calendar)
            guard days.contains(weekday.rawValue) else {
                continue
            }

            guard let candidate = calendar.date(
                bySettingHour: time.hour ?? 0,
                minute: time.minute ?? 0,
                second: time.second ?? 0,
                of: day
            ) else {
                continue
            }

            if candidate >= referenceDate {
                return candidate
            }
        }

        return nil
    }

    private func normalizedRepeatDays(_ repeatDays: Set<Int>?) -> Set<Int> {
        guard let repeatDays else { return [] }
        return Set(repeatDays.filter { 1...7 ~= $0 })
    }
}
