import SwiftUI
import Foundation

/// Storage, widget and about information.
///
/// Everything shown here is read from the live configuration and the live
/// message library — there is no sample data behind this screen.
struct SettingsView: View {
    @EnvironmentObject private var manager: MessageManager

    @State private var refreshFeedback: String?

    var body: some View {
        NavigationStack {
            List {
                storageSection
                widgetSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .whisperScreenBackground()
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private var storageSection: some View {
        Section {
            LabeledContent("Saved messages", value: "\(manager.messages.count)")

            LabeledContent("Shared storage") {
                Text(SharedStorageURLFactory.makeStorageURL().lastPathComponent)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            LabeledContent {
                Label(
                    usesSharedContainer ? "Available" : "Unavailable",
                    systemImage: usesSharedContainer ? "checkmark.circle" : "xmark.circle"
                )
                .foregroundStyle(usesSharedContainer ? AppColors.accentLight : AppColors.danger)
            } label: {
                Text("App Group")
            }
            .accessibilityLabel("App Group \(usesSharedContainer ? "available" : "unavailable")")
        } header: {
            Text("Storage")
                .textCase(nil)
        } footer: {
            Text(
                usesSharedContainer
                    ? "Messages are stored in the App Group container, which is how the widget reads them."
                    : "The App Group container is not reachable, so the widget cannot read new messages yet. Enable the App Group capability for both targets."
            )
            .font(AppTypography.caption)
        }
    }

    private var widgetSection: some View {
        Section {
            Button {
                manager.refreshWidget()
                refreshFeedback = "Widget timelines reloaded."
            } label: {
                Label("Reload widget now", systemImage: "arrow.clockwise")
            }
            .accessibilityHint("Asks WidgetKit to rebuild the widget timeline")

            if let refreshFeedback {
                Text(refreshFeedback)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accentLight)
                    .accessibilityLabel(refreshFeedback)
            }
        } header: {
            Text("Widget")
                .textCase(nil)
        } footer: {
            Text("iOS decides when widget content is refreshed. Editing a message already requests a reload automatically.")
                .font(AppTypography.caption)
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Widget kind", value: WhisperStorageConfiguration.widgetKind)
        } header: {
            Text("About")
                .textCase(nil)
        } footer: {
            Text("Touch and hold the Home Screen or Lock Screen, tap the plus button, then search for Whisper to add the widget.")
                .font(AppTypography.caption)
        }
    }

    // MARK: - State

    private var usesSharedContainer: Bool {
        SharedStorageURLFactory.isUsingAppGroupContainer()
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "1.0") (\(build ?? "1"))"
    }
}
