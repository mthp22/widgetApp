import Foundation
import Combine

@MainActor
final class MessageComposerViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @Published var repeatDays: Set<Int> = []
    @Published var selectedStyle: MessageStyle = .bold
    @Published var isDateEnabled: Bool = true
    @Published var errorMessage: String?

    @Published private(set) var editingMessageID: UUID?

    var isEditing: Bool {
        editingMessageID != nil
    }

    func beginNewMessage() {
        editingMessageID = nil
        content = ""
        selectedDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        repeatDays = []
        selectedStyle = .bold
        isDateEnabled = true
        errorMessage = nil
    }

    func beginEditing(_ message: Message) {
        editingMessageID = message.id
        content = message.content
        if let scheduledDate = message.scheduledDate {
            selectedDate = scheduledDate
            isDateEnabled = true
        } else {
            selectedDate = Date()
            isDateEnabled = false
        }
        repeatDays = message.repeatDays ?? []
        selectedStyle = message.widgetStyle
        errorMessage = nil
    }

    func toggleRepeat(day: Weekday) {
        if repeatDays.contains(day.rawValue) {
            repeatDays.remove(day.rawValue)
        } else {
            repeatDays.insert(day.rawValue)
        }
    }

    func save(using manager: MessageManaging) {
        do {
            let scheduledDate = isDateEnabled ? selectedDate : nil
            if let editingMessageID {
                let message = Message(
                    id: editingMessageID,
                    content: content,
                    scheduledDate: scheduledDate,
                    repeatDays: repeatDays,
                    widgetStyle: selectedStyle
                )
                try manager.updateMessage(message)
            } else {
                try manager.createMessage(
                    content: content,
                    scheduledDate: scheduledDate,
                    repeatDays: repeatDays,
                    style: selectedStyle
                )
            }
            beginNewMessage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(using manager: MessageManaging) {
        guard let editingMessageID else { return }

        do {
            try manager.deleteMessage(id: editingMessageID)
            beginNewMessage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
