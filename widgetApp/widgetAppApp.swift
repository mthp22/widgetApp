import SwiftUI

@main
struct WhisperWidgetApp: App {
    @StateObject private var messageManager: MessageManager

    init() {
        let repository = SharedFileMessageRepository()
        let resolver = MessageScheduleResolver()

        #if canImport(WidgetKit)
        let reloader: WidgetReloading = WidgetCenterReloader()
        #else
        let reloader: WidgetReloading = NoOpWidgetReloader()
        #endif

        _messageManager = StateObject(
            wrappedValue: MessageManager(
                repository: repository,
                resolver: resolver,
                widgetReloader: reloader
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(messageManager)
                .preferredColorScheme(.dark)
        }
    }
}
