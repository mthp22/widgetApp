import Foundation

enum Weekday: Int, CaseIterable, Codable, Identifiable {
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
        case .monday:
            "Mon"
        case .tuesday:
            "Tue"
        case .wednesday:
            "Wed"
        case .thursday:
            "Thu"
        case .friday:
            "Fri"
        case .saturday:
            "Sat"
        case .sunday:
            "Sun"
        }
    }

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        let weekday = calendar.component(.weekday, from: date)
        let mondayBased = weekday == 1 ? 7 : weekday - 1
        return Weekday(rawValue: mondayBased) ?? .monday
    }

    var calendarWeekdayValue: Int {
        rawValue == 7 ? 1 : rawValue + 1
    }
}
