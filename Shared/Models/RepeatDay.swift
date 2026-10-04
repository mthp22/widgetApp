import Foundation

/// Strongly typed weekday used by repeating message schedules.
///
/// Raw values follow the persisted `Message.repeatDays` representation:
/// `1 = Monday … 7 = Sunday`. This numbering is deliberately *not* the
/// `Calendar` weekday numbering (which is `1 = Sunday … 7 = Saturday`);
/// conversion between the two happens only through the helpers below.
enum RepeatDay: Int, CaseIterable, Codable, Identifiable, Hashable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }

    var fullName: String {
        switch self {
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        case .sunday: "Sunday"
        }
    }

    /// The `Calendar` weekday value (`1 = Sunday … 7 = Saturday`) for this day.
    var calendarWeekdayValue: Int {
        rawValue == 7 ? 1 : rawValue + 1
    }

    /// Maps a date onto its Monday-based repeat day.
    static func from(date: Date, calendar: Calendar = .current) -> RepeatDay {
        let weekday = calendar.component(.weekday, from: date)
        let mondayBased = weekday == 1 ? 7 : weekday - 1
        return RepeatDay(rawValue: mondayBased) ?? .monday
    }

    /// Normalizes an arbitrary persisted set of day numbers, dropping invalid values.
    static func normalized(_ values: Set<Int>?) -> Set<Int> {
        guard let values else { return [] }
        return Set(values.filter { rawValue in (1...7).contains(rawValue) })
    }

    /// Formats a set of day numbers for display, e.g. `"Mon, Wed, Fri"`.
    static func shortNames(for values: Set<Int>) -> String {
        let normalized = normalized(values)
        return allCases
            .filter { normalized.contains($0.rawValue) }
            .map(\.shortName)
            .joined(separator: ", ")
    }
}
