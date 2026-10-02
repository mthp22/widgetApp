import WidgetKit
import SwiftUI

/// Renders a ``WhisperWidgetEntry`` for the family WidgetKit asks for.
///
/// The view is intentionally small: all decisions about *what* to show are made
/// upstream by `WidgetDataSource`, so this file only lays content out.
struct WhisperWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: WhisperWidgetEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineBody
        case .accessoryCircular:
            circularBody
        case .accessoryRectangular:
            rectangularBody
        default:
            systemBody
        }
    }

    // MARK: - Home Screen / standby

    private var systemBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            brandMark
            Spacer(minLength: 0)
            messageBody
            captionBody
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            ZStack {
                AppColors.surface
                AppColors.backgroundGlow
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var brandMark: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppColors.accentGradient)
                .frame(width: 6, height: 6)

            Text("Whisper")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textMuted)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var messageBody: some View {
        switch entry.content {
        case let .message(message, _, _):
            Text(message.normalizedContent)
                .font(message.widgetStyle.font)
                .foregroundStyle(message.widgetStyle.foregroundColor)
                .lineLimit(6)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .empty:
            placeholderBody(
                systemImage: "moon.stars",
                title: "No message scheduled",
                subtitle: "Add one in WhisperWidget"
            )

        case .unavailable:
            placeholderBody(
                systemImage: "exclamationmark.triangle",
                title: "Messages unavailable",
                subtitle: "Open WhisperWidget to reload"
            )
        }
    }

    private var captionBody: some View {
        Group {
            if let caption = entry.caption {
                Text(caption)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }
        }
        .accessibilityHidden(true)
    }

    private func placeholderBody(systemImage: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.accentGradient)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Lock Screen

    private var inlineBody: some View {
        Text(entry.compactText)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var rectangularBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.compactText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if let caption = entry.caption {
                Text(caption)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var circularBody: some View {
        Text(entry.compactText)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(entry.compactText)
    }
}
