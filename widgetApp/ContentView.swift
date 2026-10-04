import SwiftUI

/// Root of the interface: two tabs, one for the message library and one for
/// storage/widget settings.
struct ContentView: View {
    @EnvironmentObject private var manager: MessageManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            MessageListView()
                .tabItem {
                    Label("Messages", systemImage: "text.bubble")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppColors.accentLight)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reloadOnActivation()
            }
        }
    }

    /// Picks up changes made while the app was in the background (for example
    /// an iCloud-restored library or a future extension writing to the store).
    private func reloadOnActivation() {
        do {
            try manager.reload()
        } catch {
            // `reload()` records the failure in `lastPersistenceError`, which
            // the message list renders as a visible storage problem.
        }
    }
}
