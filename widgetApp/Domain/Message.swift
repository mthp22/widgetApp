import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: UUID
    var content: String
    var scheduledDate: Date?
    var repeatDays: Set<Int>?
    var widgetStyle: MessageStyle

    init(
        id: UUID = UUID(),
        content: String,
        scheduledDate: Date?,
        repeatDays: Set<Int>?,
        widgetStyle: MessageStyle
    ) {
        self.id = id
        self.content = content
        self.scheduledDate = scheduledDate
        self.repeatDays = repeatDays?.isEmpty == true ? nil : repeatDays
        self.widgetStyle = widgetStyle
    }

    var normalizedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasRepeatingSchedule: Bool {
        guard let repeatDays else { return false }
        return !repeatDays.isEmpty
    }
}
