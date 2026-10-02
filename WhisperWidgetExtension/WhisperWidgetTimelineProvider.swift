#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

struct WhisperWidgetEntryViewPalette: TimelineProvider {
    typealias Entry = WhisperWidgetEntry

    private let managerFactory: () -> MessageManager

    init(managerFactory: @escaping () -> MessageManager = WhisperWidgetEntryViewPalette.defaultManagerFactory) {
        self.managerFactory = managerFactory
    }

    func placeholder(in context: Context) -> WhisperWidgetEntry {
        WhisperWidgetEntry(date: Date(), text: "No message scheduled", style: .formal)
    }

    func getSnapshot(in context: Context, completion: @escaping (WhisperWidgetEntry) -> Void) {
        completion(currentEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WhisperWidgetEntry>) -> Void) {
        let now = Date()
        let manager = managerFactory()
        let currentEntry = currentEntry(at: now, manager: manager)

        let nextRefreshDate: Date
        if let scheduled = manager.nextScheduledEntry(at: now), scheduled.fireDate > now {
            nextRefreshDate = scheduled.fireDate
        } else {
            nextRefreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
        }

        completion(Timeline(entries: [currentEntry], policy: .after(nextRefreshDate)))
    }

    private func currentEntry(at date: Date, manager: MessageManager? = nil) -> WhisperWidgetEntry {
        let manager = manager ?? managerFactory()

        guard let scheduled = manager.nextScheduledEntry(at: date) else {
            return WhisperWidgetEntry(
                date: date,
                text: "No message scheduled",
                style: .formal
            )
        }

        return WhisperWidgetEntry(
            date: date,
            text: scheduled.message.content,
            style: scheduled.message.widgetStyle
        )
    }

    private static func defaultManagerFactory() -> MessageManager {
        MessageManager(
            repository: SharedFileMessageRepository(),
            resolver: MessageScheduleResolver(),
            widgetReloader: NoOpWidgetReloader(),
            backgroundChecksEnabled: false
        )
    }
}
#endif
