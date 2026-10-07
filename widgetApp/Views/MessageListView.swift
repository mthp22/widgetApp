import SwiftUI
import Foundation

/// Library screen: shows the persisted messages, the one the widget currently
/// renders, real search over the local library, and entry points to compose,
/// edit and delete.
struct MessageListView: View {
    @EnvironmentObject private var manager: MessageManager

    @State private var searchText = ""
    @State private var isComposing = false
    @State private var editingMessage: Message?

    var body: some View {
        NavigationStack {
            List {
                currentWidgetSection
                librarySection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .whisperScreenBackground()
            .navigationTitle("WhisperWidget")
            .whisperToolbarBackground()
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search your messages"
            )
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isComposing = true
                    } label: {
                        Label("New message", systemImage: "plus")
                    }
                    .accessibilityIdentifier("messages.newButton")
                    .accessibilityHint("Creates a new message")
                }
            }
            .navigationDestination(for: Message.self) { message in
                MessageDetailView(messageID: message.id)
            }
            .sheet(isPresented: $isComposing) {
                MessageComposerView()
            }
            .sheet(item: $editingMessage) { message in
                MessageComposerView(initialMessage: message)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var currentWidgetSection: some View {
        if let display = manager.currentDisplay(at: Date()) {
            Section {
                currentWidgetCard(for: display)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .transition(.whisperSettle)
            } header: {
                Text(display.phase == .active ? "On your widget now" : "Next on your widget")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(nil)
            }
        }
    }

    @ViewBuilder
    private var librarySection: some View {
        if manager.messages.isEmpty {
            EmptyStateView(
                systemImage: "moon.stars",
                title: "No messages yet",
                message: "Write your first message and it will appear on your widget and Lock Screen.",
                actionTitle: "Compose Message"
            ) {
                isComposing = true
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .transition(.whisperSettle)
        } else if filteredMessages.isEmpty {
            EmptyStateView(
                systemImage: "magnifyingglass",
                title: "No matches",
                message: "Nothing matches “\(searchText)”. Try a different search."
            )
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
        } else {
            Section {
                ForEach(Array(filteredMessages.enumerated()), id: \.element.id) { index, message in
                    NavigationLink(value: message) {
                        MessageRow(
                            message: message,
                            isCurrent: message.id == currentMessageID
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                    .listRowSeparator(.hidden)
                    .transition(.whisperRise)
                    .animation(
                        AppMotion.entrance.delay(
                            Double(min(index, AppMotion.staggerCap)) * AppMotion.stagger
                        ),
                        value: manager.messages.count
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(message)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("Saved Messages (\(manager.messages.count))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .textCase(nil)
            }
        }

        if let persistenceError = manager.lastPersistenceError {
            Section {
                Label(persistenceError, systemImage: "exclamationmark.triangle")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.danger)
                    .listRowBackground(AppColors.surface2)
            } header: {
                Text("Storage problem")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.danger)
                    .textCase(nil)
            }
        }
    }

    // MARK: - Pieces

    private func currentWidgetCard(for display: MessageDisplay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(display.message.normalizedContent)
                .font(display.message.widgetStyle.font)
                .foregroundStyle(display.message.widgetStyle.foregroundColor)
                .lineLimit(3)

            Text(MessageScheduleText.scheduleLabel(for: display.message))
                .font(AppTypography.caption)
                .tracking(AppTypography.captionTracking)
                .foregroundStyle(AppColors.textMuted)

            if display.phase == .upcoming {
                Label(
                    "Starts \(WhisperFormat.dateTime(display.effectiveDate))",
                    systemImage: "clock"
                )
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .whisperGlass(cornerRadius: AppTheme.cardCornerRadius, padding: 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Derived state

    private var currentMessageID: UUID? {
        manager.currentDisplay(at: Date())?.message.id
    }

    /// Real search over the persisted library, ordered by upcoming occurrence.
    private var filteredMessages: [Message] {
        let now = Date()
        let currentID = currentMessageID
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = manager.messages.filter { message in
            guard query.isEmpty else {
                return message.normalizedContent.localizedCaseInsensitiveContains(query)
            }
            return true
        }

        return filtered.sorted { lhs, rhs in
            if lhs.id == currentID { return true }
            if rhs.id == currentID { return false }

            let lhsNext = manager.scheduledDate(for: lhs, after: now)
            let rhsNext = manager.scheduledDate(for: rhs, after: now)

            switch (lhsNext, rhsNext) {
            case let (lhsNext?, rhsNext?):
                if lhsNext == rhsNext {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhsNext < rhsNext
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.id.uuidString < rhs.id.uuidString
            }
        }
    }

    private func delete(_ message: Message) {
        do {
            try manager.deleteMessage(id: message.id)
        } catch {
            // Failures are surfaced by `MessageManager.lastPersistenceError`,
            // which renders as a visible storage problem section.
        }
    }
}
