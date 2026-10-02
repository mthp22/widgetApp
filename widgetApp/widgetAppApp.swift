import SwiftUI

@main
struct WhisperWidgetApp: App {
    @StateObject private var messageManager: MessageManager

    init() {
        let container = AppContainer.live()
        _messageManager = StateObject(wrappedValue: container.makeMessageManager())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(messageManager)
                .preferredColorScheme(.dark)
        }
    }
}
