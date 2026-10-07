import Foundation

/// English (South Africa) presentation rules for every user-facing date and
/// time in the application.
///
/// The locale pins spelling, date order and calendar conventions to `en_ZA`
/// while the **hour cycle follows the device setting**, so a user running a
/// 12-hour clock still sees `6:07 PM` and a 24-hour user sees `18:07`.
enum WhisperFormat {
    /// `en_ZA` with the hour cycle taken from the device preference.
    ///
    /// The Unicode locale extension `hc` forces the hour cycle without
    /// changing any other `en_ZA` convention (date order, spelling, calendar).
    static var locale: Locale {
        Locale(identifier: deviceUses12HourClock ? "en_ZA-u-hc-h12" : "en_ZA-u-hc-h23")
    }

    /// `true` when the device is configured for a 12-hour clock.
    private static var deviceUses12HourClock: Bool {
        guard let pattern = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current) else {
            return false
        }
        return !pattern.contains("H")
    }

    /// Shared "2 Oct 2026, 18:07" style used across the UI.
    static func dateTime(_ date: Date) -> String {
        date.formatted(dateStyle)
    }

    /// Time only — "18:07".
    static func time(_ date: Date) -> String {
        date.formatted(timeStyle)
    }

    // MARK: - Styles

    private static var dateStyle: Date.FormatStyle {
        var style = Date.FormatStyle(date: .abbreviated, time: .shortened)
        style.locale = locale
        return style
    }

    private static var timeStyle: Date.FormatStyle {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.locale = locale
        return style
    }
}
