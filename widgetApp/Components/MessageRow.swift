import SwiftUI
import Foundation

/// Human readable schedule descriptions for a message.
enum MessageScheduleText {
    /// Label describing when a message applies, e.g.
    /// `"Repeats Mon, Wed · 8:30 AM"` or `"In effect since Jan 7, 2026 at 8:30 AM"`.
    static func scheduleLabel(for message: Message) -> String {
        scheduleLabel(scheduledDate: message.scheduledDate, repeatDays: message.repeatDays)
    }

    /// Same as ``scheduleLabel(for:)`` for values that are not persisted yet.
    static func scheduleLabel(scheduledDate: Date?, repeatDays: Set<Int>?) -> String {
        let days = RepeatDay.normalized(repeatDays)

        if !days.isEmpty {
            let names = RepeatDay.shortNames(for: days)
            if let time = scheduledDate {
                return "Repeats \(names) · \(WhisperFormat.time(time))"
            }
            return "Repeats \(names)"
        }

        guard let scheduledDate else {
            return "Applies immediately"
        }

        if scheduledDate > Date() {
            return "One-time · \(WhisperFormat.dateTime(scheduledDate))"
        }

        return "In effect since \(WhisperFormat.dateTime(scheduledDate))"
    }

    /// VoiceOver friendly description combining content, schedule and style.
    static func accessibilityLabel(for message: Message) -> String {
        "\(message.normalizedContent). \(scheduleLabel(for: message)). Style: \(message.widgetStyle.title)."
    }
}

/// One row in the message library.
struct MessageRow: View {
    let message: Message
    /// Marks the message the widget is currently rendering.
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(message.normalizedContent)
                    .font(message.widgetStyle.font)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                if isCurrent {
                    CurrentBadge()
                }
            }

            HStack(spacing: 8) {
                Text(MessageScheduleText.scheduleLabel(for: message))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)

                Text(message.widgetStyle.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppColors.accentSoft)
                    .overlay {
                        Capsule().stroke(AppColors.accent.opacity(0.35), lineWidth: 1)
                    }
                    .clipShape(Capsule())
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .whisperRow()
        .accessibilityIdentifier("messageRow.\(message.id.uuidString)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MessageScheduleText.accessibilityLabel(for: message))
        .accessibilityHint(isCurrent ? "Currently shown in the widget" : "")
        .accessibilityAddTraits(.isButton)
    }
}

/// Small "On widget" indicator — state is communicated by text, not colour alone.
private struct CurrentBadge: View {
    var body: some View {
        Text("On widget")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.surface)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColors.accent)
            .clipShape(Capsule())
            .accessibilityLabel("Currently shown in the widget")
    }
}
