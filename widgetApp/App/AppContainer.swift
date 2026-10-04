import Foundation

/// Composition root of the application.
///
/// Every long-lived dependency is created exactly once, here, and handed to the
/// object graph that needs it. Views never construct storage or scheduling
/// types themselves, which keeps the wiring in one reviewable place.
@MainActor
struct AppContainer {
    let repository: MessageRepository
    let scheduleResolver: MessageScheduleResolving
    let widgetReloader: WidgetReloading

    /// Container wired to the live App Group store and WidgetKit.
    static func live() -> AppContainer {
        AppContainer(
            repository: SharedFileMessageRepository(),
            scheduleResolver: MessageScheduleResolver(),
            widgetReloader: WidgetCenterReloader()
        )
    }

    /// The application-wide message store.
    func makeMessageManager() -> MessageManager {
        MessageManager(
            repository: repository,
            resolver: scheduleResolver,
            widgetReloader: widgetReloader
        )
    }
}
