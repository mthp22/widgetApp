import SwiftUI

struct MessageComposerView: View {
    @EnvironmentObject private var manager: MessageManager
    @StateObject private var viewModel = MessageComposerViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    composerCard
                    scheduledMessagesCard
                }
                .padding(16)
            }
            .background(backgroundView)
            .navigationTitle("WhisperWidget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") {
                        viewModel.beginNewMessage()
                    }
                    .tint(WhisperTheme.accentLight)
                }
            }
            .onAppear {
                if !viewModel.isEditing && viewModel.content.isEmpty {
                    viewModel.beginNewMessage()
                }
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            WhisperTheme.surface
                .ignoresSafeArea()

            RadialGradient(
                colors: [WhisperTheme.accentDark.opacity(0.2), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Curated lock-screen messages")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(WhisperTheme.accentGradient)

            Text("Set the next message with schedule, repeat days, and style. The widget always renders the next active one.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(WhisperTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(WhisperTheme.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(WhisperTheme.accentDark.opacity(0.45), lineWidth: 1)
        )
    }

    private var composerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.isEditing ? "Edit Message" : "Compose Message")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(WhisperTheme.textPrimary)

            TextField("Write your message", text: $viewModel.content, axis: .vertical)
                .lineLimit(4...6)
                .padding(12)
                .background(WhisperTheme.card)
                .foregroundColor(WhisperTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(WhisperTheme.accentDark.opacity(0.35), lineWidth: 1)
                )

            Toggle(isOn: $viewModel.isDateEnabled) {
                Text("Schedule for a specific time")
                    .foregroundColor(WhisperTheme.textPrimary)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .tint(WhisperTheme.accentLight)

            if viewModel.isDateEnabled {
                DatePicker(
                    "Date & Time",
                    selection: $viewModel.selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .colorScheme(.dark)
                .accentColor(WhisperTheme.accentLight)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Repeat Days")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(WhisperTheme.textPrimary)

                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        DayToggleChip(
                            day: day,
                            isSelected: viewModel.repeatDays.contains(day.rawValue)
                        ) {
                            viewModel.toggleRepeat(day: day)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Text Style")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(WhisperTheme.textPrimary)

                Picker("Text Style", selection: $viewModel.selectedStyle) {
                    ForEach(MessageStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            previewPanel

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.red.opacity(0.9))
            }

            HStack(spacing: 12) {
                Button(action: { viewModel.save(using: manager) }) {
                    Text(viewModel.isEditing ? "Update" : "Save")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(AccentButtonStyle())

                if viewModel.isEditing {
                    Button(action: { viewModel.delete(using: manager) }) {
                        Text("Delete")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(SubtleButtonStyle())
                }
            }
        }
        .padding(16)
        .background(WhisperTheme.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(WhisperTheme.accentDark.opacity(0.45), lineWidth: 1)
        )
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(WhisperTheme.textMuted)

            Text(viewModel.content.isEmpty ? "Your message appears here" : viewModel.content)
                .font(viewModel.selectedStyle.font)
                .foregroundColor(Color(hex: viewModel.selectedStyle.foregroundHex))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(hex: viewModel.selectedStyle.backgroundHex).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(WhisperTheme.accentDark.opacity(0.4), lineWidth: 1)
                )
        }
    }

    private var scheduledMessagesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Messages")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(WhisperTheme.textPrimary)

            if manager.messages.isEmpty {
                Text("No messages yet")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(WhisperTheme.textMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 10) {
                    ForEach(manager.messages) { message in
                        MessageRow(message: message) {
                            viewModel.beginEditing(message)
                        }
                    }
                }
            }

            if let persistenceError = manager.lastPersistenceError {
                Text("Persistence error: \(persistenceError)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.red.opacity(0.9))
            }
        }
        .padding(16)
        .background(WhisperTheme.panelGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(WhisperTheme.accentDark.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct DayToggleChip: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(day.shortName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? WhisperTheme.surface : WhisperTheme.textPrimary)
            .background(isSelected ? WhisperTheme.accentGradient : LinearGradient(colors: [WhisperTheme.card], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MessageRow: View {
    let message: Message
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(message.content)
                    .font(message.widgetStyle.font)
                    .lineLimit(2)
                    .foregroundColor(Color(hex: message.widgetStyle.foregroundHex))

                if let scheduledDate = message.scheduledDate {
                    Text(scheduleLabel(for: message, scheduledDate: scheduledDate))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(WhisperTheme.textMuted)
                } else {
                    Text("Shows immediately")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(WhisperTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(WhisperTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(WhisperTheme.accentDark.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func scheduleLabel(for message: Message, scheduledDate: Date) -> String {
        let formattedDate = scheduledDate.formatted(date: .abbreviated, time: .shortened)

        guard let repeatDays = message.repeatDays, !repeatDays.isEmpty else {
            return "One-time: \(formattedDate)"
        }

        let labels = Weekday.allCases
            .filter { repeatDays.contains($0.rawValue) }
            .map(\.shortName)
            .joined(separator: ", ")

        return "Repeats: \(labels) at \(scheduledDate.formatted(date: .omitted, time: .shortened))"
    }
}

private struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundColor(WhisperTheme.surface)
            .background(
                WhisperTheme.accentGradient
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(WhisperTheme.textPrimary)
            .background(WhisperTheme.card.opacity(configuration.isPressed ? 0.6 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(WhisperTheme.accentDark.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
