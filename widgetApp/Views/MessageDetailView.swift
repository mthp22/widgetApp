import SwiftUI
import Foundation

/// Read-only detail for one persisted message, with edit and delete actions.
struct MessageDetailView: View {
    @EnvironmentObject private var manager: MessageManager
    @Environment(\.dismiss) private var dismiss

    let messageID: UUID

    @State private var editingMessage: Message?
    @State private var isConfirmingDelete = false

    private var message: Message? {
        manager.messages.first { $0.id == messageID }
    }

    var body: some View {
        Group {
            if let message {
                content(for: message)
            } else {
                EmptyStateView(
                    systemImage: "trash",
                    title: "Message deleted",
                    message: "This message is no longer in your library."
                )
            }
        }
        .whisperScreenBackground()
        .navigationTitle("Message")
        .navigationBarTitleDisplayMode(.inline)
        .whisperToolbarBackground()
        .sheet(item: $editingMessage) { message in
            MessageComposerView(initialMessage: message)
        }
        .confirmationDialog(
            "Delete this message?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The widget stops showing it immediately.")
        }
    }

    // MARK: - Content

    private func content(for message: Message) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                previewCard(for: message)
                    .transition(.whisperSettle)
                scheduleCard(for: message)
                    .transition(.whisperSettle)
                actions
                    .transition(.whisperSettle)
            }
            .padding(AppTheme.sectionSpacing)
            .animation(AppMotion.entrance, value: message.id)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func previewCard(for message: Message) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text(message.normalizedContent)
                .font(message.widgetStyle.font)
                .foregroundStyle(message.widgetStyle.foregroundColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.controlPadding)
                .background(message.widgetStyle.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                }

            Label(message.widgetStyle.accessibilityDescription, systemImage: "paintbrush")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .whisperCard()
    }

    private func scheduleCard(for message: Message) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schedule")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            Label(MessageScheduleText.scheduleLabel(for: message), systemImage: "calendar")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            if let next = manager.scheduledDate(for: message, after: Date()) {
                Label(
                    "Next occurrence \(WhisperFormat.dateTime(next))",
                    systemImage: "clock"
                )
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.accent)
            } else {
                Label("No future occurrence", systemImage: "clock.badge.exclamationmark")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            if message.id == manager.currentDisplay(at: Date())?.message.id {
                Label("Currently shown on your widget", systemImage: "checkmark.circle")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .whisperCard()
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                editingMessage = message
            } label: {
                Text("Edit Message")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(message == nil)

            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Text("Delete Message")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(DangerButtonStyle())
            .accessibilityHint("Removes this message from your library and widget")
        }
    }

    private func delete() {
        do {
            try manager.deleteMessage(id: messageID)
            dismiss()
        } catch {
            // Surfaced by `MessageManager.lastPersistenceError` on the list screen.
        }
    }
}
