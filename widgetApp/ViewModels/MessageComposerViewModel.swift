import Foundation
import Combine

/// Editing state for the message composer.
///
/// The view model owns only the transient form state; persistence and widget
/// refresh happen through `MessageManaging`, so saving performs a real update
/// of the shared library.
@MainActor
final class MessageComposerViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedDate: Date
    @Published var repeatDays: Set<Int> = []
    @Published var selectedStyle: MessageStyle = .bold
    @Published var isDateEnabled: Bool = true
    @Published var errorMessage: String?
    @Published private(set) var editingMessageID: UUID?

    init(initialMessage: Message? = nil, now: Date = Date()) {
        self.selectedDate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now

        if let initialMessage {
            apply(initialMessage)
        } else {
            resetToNewMessage()
        }
    }

    var isEditing: Bool {
        editingMessageID != nil
    }

    var title: String {
        isEditing ? "Edit Message" : "New Message"
    }

    var saveButtonTitle: String {
        isEditing ? "Update" : "Save"
    }

    var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The date persisted for the current form state.
    ///
    /// Repeating messages always keep a date because it anchors the time of day
    /// they repeat at; a non-repeating message with the toggle off is persisted
    /// without a date so it applies immediately.
    var resolvedScheduledDate: Date? {
        if isDateEnabled || !repeatDays.isEmpty {
            return selectedDate
        }
        return nil
    }

    // MARK: Form lifecycle

    func resetToNewMessage() {
        editingMessageID = nil
        content = ""
        selectedDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        repeatDays = []
        selectedStyle = .bold
        isDateEnabled = true
        errorMessage = nil
    }

    func beginEditing(_ message: Message) {
        apply(message)
    }

    private func apply(_ message: Message) {
        editingMessageID = message.id
        content = message.content

        if let scheduledDate = message.scheduledDate {
            selectedDate = scheduledDate
            isDateEnabled = true
        } else {
            selectedDate = Date()
            isDateEnabled = false
        }

        repeatDays = RepeatDay.normalized(message.repeatDays)
        selectedStyle = message.widgetStyle
        errorMessage = nil
    }

    // MARK: Actions

    func toggleRepeat(day: RepeatDay) {
        if repeatDays.contains(day.rawValue) {
            repeatDays.remove(day.rawValue)
        } else {
            repeatDays.insert(day.rawValue)
        }
    }

    /// Persists the current form. Returns `true` when the save succeeded so the
    /// view can dismiss itself.
    func save(using manager: MessageManaging) -> Bool {
        errorMessage = nil

        do {
            if let editingMessageID {
                try manager.updateMessage(
                    Message(
                        id: editingMessageID,
                        content: content,
                        scheduledDate: resolvedScheduledDate,
                        repeatDays: repeatDays,
                        widgetStyle: selectedStyle
                    )
                )
            } else {
                try manager.createMessage(
                    content: content,
                    scheduledDate: resolvedScheduledDate,
                    repeatDays: repeatDays,
                    style: selectedStyle
                )
            }

            resetToNewMessage()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Deletes the message being edited. Returns `true` on success.
    func delete(using manager: MessageManaging) -> Bool {
        errorMessage = nil

        guard let editingMessageID else { return false }

        do {
            try manager.deleteMessage(id: editingMessageID)
            resetToNewMessage()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
