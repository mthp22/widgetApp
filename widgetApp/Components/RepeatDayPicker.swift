import SwiftUI
import Foundation

/// Weekday selection control for repeating schedules.
struct RepeatDayPicker: View {
    let selection: Set<Int>
    let onToggle: (RepeatDay) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat Days")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 6) {
                ForEach(RepeatDay.allCases) { day in
                    DayToggleChip(
                        day: day,
                        isSelected: selection.contains(day.rawValue)
                    ) {
                        onToggle(day)
                    }
                }
            }

            Text(hint)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .accessibilityLabel(hint)
        }
        .accessibilityElement(children: .contain)
    }

    private var hint: String {
        if RepeatDay.normalized(selection).isEmpty {
            "No repeat days — this message applies once."
        } else {
            "Repeating \(RepeatDay.shortNames(for: selection)) each week."
        }
    }
}

private struct DayToggleChip: View {
    let day: RepeatDay
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                Text(day.shortName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? AppColors.surface : AppColors.textPrimary)
            .background(isSelected ? AnyShapeStyle(AppColors.accent) : AnyShapeStyle(AppColors.surface2))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.chipCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.fullName)
        .accessibilityHint(isSelected ? "Selected, double tap to remove" : "Double tap to repeat on this day")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
