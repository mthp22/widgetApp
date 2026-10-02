import SwiftUI
import Foundation

/// Primary screen for creating and editing messages.
///
/// Saving writes to the shared library through `MessageManager`, which persists
/// first and then asks WidgetKit to refresh; cancelling simply dismisses.
struct MessageComposerView: View {
    @EnvironmentObject private var manager: MessageManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: MessageComposerViewModel

    init(initialMessage: Message? = nil) {
        _viewModel = StateObject(
            wrappedValue: MessageComposerViewModel(initialMessage: initialMessage)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    composerCard
                }
                .padding(AppTheme.sectionSpacing)
            }
            .scrollBounceBehavior(.basedOnSize)
            .whisperScreenBackground()
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("composer.cancelButton")
                    .accessibilityHint("Discards the changes and closes the composer")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveButtonTitle) {
                        if viewModel.save(using: manager) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityIdentifier("composer.saveButton")
                    .accessibilityHint(viewModel.isEditing ? "Updates the saved message" : "Saves the new message")
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Composer

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.isEditing ? "Edit Message" : "Compose Message")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            messageField

            scheduleSection

            StylePicker(selection: $viewModel.selectedStyle)

            previewPanel

            if let errorMessage = viewModel.errorMessage {
                errorText(errorMessage)
            }

            if viewModel.isEditing {
                Button(role: .destructive) {
                    if viewModel.delete(using: manager) {
                        dismiss()
                    }
                } label: {
                    Text("Delete Message")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(DangerButtonStyle())
                .accessibilityIdentifier("composer.deleteButton")
                .accessibilityHint("Removes this message from the library")
            }
        }
        .whisperCard()
    }

    private var messageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Message")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            TextField("Write your message", text: $viewModel.content, axis: .vertical)
                .lineLimit(4...7)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .padding(AppTheme.controlPadding)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                }
                .accessibilityLabel("Message text")
                .accessibilityIdentifier("composer.messageField")

            Text("\(viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).count) characters")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
                .accessibilityHidden(true)
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $viewModel.isDateEnabled) {
                Text("Schedule for a specific time")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accentLight)

            if viewModel.isDateEnabled {
                DatePicker(
                    "Date & Time",
                    selection: $viewModel.selectedDate,
                    in: dateRange,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .colorScheme(.dark)
                .tint(AppColors.accentLight)
                .accessibilityLabel("Scheduled date and time")
            }

            RepeatDayPicker(selection: viewModel.repeatDays) { day in
                viewModel.toggleRepeat(day: day)
            }

            if !viewModel.repeatDays.isEmpty && !viewModel.isDateEnabled {
                Text("A repeat time is kept automatically so the message repeats at a stable time of day.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    /// The picker must always contain the current selection, otherwise SwiftUI
    /// traps when editing a message whose date is in the past.
    private var dateRange: PartialRangeFrom<Date> {
        min(Date(), viewModel.selectedDate)...
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Widget Preview")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text(previewText)
                .font(viewModel.selectedStyle.font)
                .foregroundStyle(viewModel.selectedStyle.foregroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.controlPadding)
                .background(viewModel.selectedStyle.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                }
                .accessibilityLabel("Widget preview: \(previewText)")

            if let scheduledDate = viewModel.resolvedScheduledDate {
                Text(MessageScheduleText.scheduleLabel(
                    scheduledDate: scheduledDate,
                    repeatDays: viewModel.repeatDays
                ))
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
            } else {
                Text("Applies immediately")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
    }

    private var previewText: String {
        let trimmed = viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nothing to preview yet" : trimmed
    }

    private func errorText(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.danger)
            .accessibilityLabel("Error: \(message)")
    }
}
