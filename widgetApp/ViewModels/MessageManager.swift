import Foundation
import Combine

protocol MessageManaging: AnyObject {
    var messages: [Message] { get }
    func reload() throws
    func createMessage(content: String, scheduledDate: Date?, repeatDays: Set<Int>?, style: MessageStyle) throws
    func updateMessage(_ message: Message) throws
    func deleteMessage(id: UUID) throws
    func nextScheduledEntry(at date: Date) -> ScheduledMessage?
}

final class MessageManager: ObservableObject, MessageManaging {
    @Published private(set) var messages: [Message] = []
    @Published private(set) var lastPersistenceError: String?

    private let repository: MessageRepository
    private let resolver: MessageScheduleResolving
    private let widgetReloader: WidgetReloading
    private let dateProvider: () -> Date

    private var checkTimer: Timer?
    private var lastKnownEntry: ScheduledMessage?

    init(
        repository: MessageRepository,
        resolver: MessageScheduleResolving = MessageScheduleResolver(),
        widgetReloader: WidgetReloading = NoOpWidgetReloader(),
        dateProvider: @escaping () -> Date = Date.init,
        backgroundChecksEnabled: Bool = true
    ) {
        self.repository = repository
        self.resolver = resolver
        self.widgetReloader = widgetReloader
        self.dateProvider = dateProvider

        do {
            try reload()
            if backgroundChecksEnabled {
                startBackgroundScheduleChecks()
            }
        } catch {
            lastPersistenceError = error.localizedDescription
        }
    }

    deinit {
        checkTimer?.invalidate()
    }

    func reload() throws {
        messages = try repository.fetchMessages()
        refreshWidgetIfNeeded(force: true)
    }

    func createMessage(content: String, scheduledDate: Date?, repeatDays: Set<Int>?, style: MessageStyle) throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw MessageManagerError.emptyContent
        }

        let message = Message(
            content: trimmedContent,
            scheduledDate: scheduledDate,
            repeatDays: repeatDays,
            widgetStyle: style
        )

        messages.append(message)
        try persistChanges()
    }

    func updateMessage(_ message: Message) throws {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            throw MessageManagerError.messageNotFound
        }

        let trimmedContent = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw MessageManagerError.emptyContent
        }

        var updated = message
        updated.content = trimmedContent
        updated.repeatDays = updated.repeatDays?.isEmpty == true ? nil : updated.repeatDays

        messages[index] = updated
        try persistChanges()
    }

    func deleteMessage(id: UUID) throws {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            throw MessageManagerError.messageNotFound
        }

        messages.remove(at: index)
        try persistChanges()
    }

    func nextScheduledEntry(at date: Date = Date()) -> ScheduledMessage? {
        resolver.nextScheduledMessage(from: messages, after: date)
    }

    func startBackgroundScheduleChecks(interval: TimeInterval = 60) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshWidgetIfNeeded(force: false)
        }
    }

    private func persistChanges() throws {
        do {
            try repository.saveMessages(messages)
            lastPersistenceError = nil
            refreshWidgetIfNeeded(force: true)
        } catch {
            lastPersistenceError = error.localizedDescription
            throw error
        }
    }

    private func refreshWidgetIfNeeded(force: Bool) {
        let now = dateProvider()
        let currentEntry = resolver.nextScheduledMessage(from: messages, after: now)

        if force || currentEntry != lastKnownEntry {
            widgetReloader.reloadAllTimelines()
            lastKnownEntry = currentEntry
        }
    }
}

enum MessageManagerError: LocalizedError {
    case emptyContent
    case messageNotFound

    var errorDescription: String? {
        switch self {
        case .emptyContent:
            "Message content can’t be empty."
        case .messageNotFound:
            "Message no longer exists."
        }
    }
}
