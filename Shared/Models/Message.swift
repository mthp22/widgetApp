import Foundation

/// The single authoritative model for a persisted personal message.
///
/// `Message` is shared verbatim between the host application and the WidgetKit
/// extension, so it stays a plain `Codable` value type with no dependencies on
/// either target.
struct Message: Codable, Identifiable, Equatable, Hashable {
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
        self.repeatDays = Self.normalizedRepeatDays(repeatDays)
        self.widgetStyle = widgetStyle
    }

    /// User content without surrounding whitespace. Used for validation and display.
    var normalizedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// `true` when the message carries at least one valid repeating weekday.
    var hasRepeatingSchedule: Bool {
        !RepeatDay.normalized(repeatDays).isEmpty
    }

    /// `true` when the message can be rendered (non-empty content).
    var isDisplayable: Bool {
        !normalizedContent.isEmpty
    }

    /// Weekdays in ascending, human readable order.
    var sortedRepeatDays: [RepeatDay] {
        RepeatDay.normalized(repeatDays)
            .compactMap(RepeatDay.init(rawValue:))
            .sorted { $0.rawValue < $1.rawValue }
    }

    private static func normalizedRepeatDays(_ repeatDays: Set<Int>?) -> Set<Int>? {
        let normalized = RepeatDay.normalized(repeatDays)
        return normalized.isEmpty ? nil : normalized
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case scheduledDate
        case repeatDays
        case widgetStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        self.repeatDays = Self.normalizedRepeatDays(
            try container.decodeIfPresent(Set<Int>.self, forKey: .repeatDays)
        )
        self.widgetStyle = try container.decode(MessageStyle.self, forKey: .widgetStyle)
    }
}
