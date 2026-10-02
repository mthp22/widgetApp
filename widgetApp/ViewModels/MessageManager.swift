import Foundation
import Combine

/// UI facing message store: loads the library, applies validated mutations and
/// asks WidgetKit to refresh after every successful change.
///
/// Responsibilities are intentionally narrow — persistence lives behind
/// ``MessageRepository``, scheduling behind ``MessageScheduleResolving`` and
/// widget refresh behind ``WidgetReloading`` — so this type coordinates them
/// rather than reimplementing any of them.
@MainActor
protocol MessageManaging: AnyObject {
    var messages: [Message] { get }
    var lastPersistenceError: String? { get }

    func reload() throws
    func createMessage(content: String, scheduledDate: Date?, repeatDays: Set<Int>?, style: MessageStyle) throws
    func updateMessage(_ message: Message) throws
    func deleteMessage(id: UUID) throws

    func nextScheduledEntry(at date: Date) -> ScheduledMessage?
    func scheduledDate(for message: Message, after date: Date) -> Date?
    func currentDisplay(at date: Date) -> MessageDisplay?
    func refreshWidget()
}

@MainActor
final class MessageManager: ObservableObject, MessageManaging {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastPersistenceError: String?

    private let repository: MessageRepository
    private let resolver: MessageScheduleResolving
    private let widgetReloader: WidgetReloading

    init(
        repository: MessageRepository,
        resolver: MessageScheduleResolving,
        widgetReloader: WidgetReloading
    ) {
        self.repository = repository
        self.resolver = resolver
        self.widgetReloader = widgetReloader

        do {
            try reload()
        } catch {
            // `reload()` already recorded the failure in `lastPersistenceError`,
            // which the UI surfaces as a visible persistence error state.
        }
    }

    // MARK: Reading

    func reload() throws {
        do {
            messages = try repository.fetchMessages()
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error.localizedDescription
            throw error
        }
    }

    func nextScheduledEntry(at date: Date) -> ScheduledMessage? {
        resolver.nextScheduledMessage(from: messages, after: date)
    }

    func currentDisplay(at date: Date) -> MessageDisplay? {
        resolver.currentDisplay(at: date, in: messages)
    }

    func scheduledDate(for message: Message, after date: Date) -> Date? {
        resolver.scheduledDate(for: message, after: date)
    }

    /// Explicitly asks WidgetKit to rebuild every timeline, used by Settings.
    func refreshWidget() {
        widgetReloader.reloadAllTimelines()
    }

    // MARK: Mutations

    func createMessage(
        content: String,
        scheduledDate: Date?,
        repeatDays: Set<Int>?,
        style: MessageStyle
    ) throws {
        let message = try validated(
            Message(
                content: content,
                scheduledDate: scheduledDate,
                repeatDays: repeatDays,
                widgetStyle: style
            )
        )

        try persist(messages + [message])
    }

    func updateMessage(_ message: Message) throws {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            throw MessageManagerError.messageNotFound
        }

        let updated = try validated(message)
        var next = messages
        next[index] = updated

        try persist(next)
    }

    func deleteMessage(id: UUID) throws {
        guard messages.contains(where: { $0.id == id }) else {
            throw MessageManagerError.messageNotFound
        }

        try persist(messages.filter { $0.id != id })
    }

    // MARK: - Private

    /// Validates a message and normalizes it before it reaches storage.
    private func validated(_ message: Message) throws -> Message {
        guard !message.normalizedContent.isEmpty else {
            throw MessageManagerError.emptyContent
        }

        if message.hasRepeatingSchedule, message.scheduledDate == nil {
            throw MessageManagerError.missingRepeatingTime
        }

        var normalized = message
        normalized.content = message.normalizedContent
        return normalized
    }

    /// Writes `messages` first and only publishes them once storage succeeded,
    /// so in-memory state can never drift from what is actually persisted.
    private func persist(_ messages: [Message]) throws {
        do {
            try repository.saveMessages(messages)
        } catch {
            lastPersistenceError = error.localizedDescription
            throw error
        }

        self.messages = messages
        lastPersistenceError = nil
        widgetReloader.reloadAllTimelines()
    }
}

enum MessageManagerError: LocalizedError, Equatable {
    case emptyContent
    case messageNotFound
    case missingRepeatingTime

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            "Message content can’t be empty."
        case .messageNotFound:
            "That message no longer exists."
        case .missingRepeatingTime:
            "Repeating messages need a time of day to repeat at."
        }
    }
}
