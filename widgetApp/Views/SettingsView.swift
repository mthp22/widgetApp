import SwiftUI
import Foundation

/// Storage and about information.
///
/// Everything shown here is read from the live configuration and the live
/// message library — there is no sample data behind this screen.
///
/// The App Group status row and the manual widget reload section are
/// deliberately not shown: widget refreshes happen automatically every
/// 15 minutes and whenever a message changes, so nothing here needs to
/// expose or explain them.
struct SettingsView: View {
    @EnvironmentObject private var manager: MessageManager

    @State private var isConfirmingDeleteAll = false
    @State private var deleteAllFeedback: String?

    var body: some View {
        NavigationStack {
            List {
                storageSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .whisperScreenBackground()
            .navigationTitle("Settings")
            .whisperToolbarBackground()
        }
    }

    // MARK: - Sections

    private var storageSection: some View {
        Section {
            LabeledContent("Saved messages", value: "\(manager.messages.count)")

            if let deleteAllFeedback {
                Text(deleteAllFeedback)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accent)
                    .transition(.whisperRise)
                    .accessibilityLabel(deleteAllFeedback)
            }

            Button(role: .destructive) {
                isConfirmingDeleteAll = true
            } label: {
                Label("Delete all messages", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(DangerButtonStyle())
            .disabled(manager.messages.isEmpty)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .accessibilityIdentifier("settings.deleteAllButton")
            .accessibilityHint("Removes every saved message from the app and the widget")
            .confirmationDialog(
                "Delete all messages?",
                isPresented: $isConfirmingDeleteAll,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    deleteAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all \(manager.messages.count) saved messages from your library and your widget.")
            }
        } header: {
            Text("Storage")
                .textCase(nil)
        } footer: {
            Text(
                "Messages are kept in the app's shared storage, which is how the widget reads them. "
                    + "The widget refreshes automatically every 15 minutes and immediately after any change."
            )
            .font(AppTypography.caption)
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)

            NavigationLink {
                UsageView()
            } label: {
                Label("Usage", systemImage: "questionmark.circle")
            }
            .accessibilityHint("Opens a step-by-step guide to using the app")
        } header: {
            Text("About")
                .textCase(nil)
        } footer: {
            Text("Touch and hold the Home Screen or Lock Screen, tap the plus button, then search for Whisper to add the widget.")
                .font(AppTypography.caption)
        }
    }

    // MARK: - Actions

    private func deleteAll() {
        do {
            try manager.deleteAllMessages()
            deleteAllFeedback = "All messages deleted."
        } catch {
            // Failures surface through `MessageManager.lastPersistenceError`,
            // which the message list renders as a storage problem.
            deleteAllFeedback = nil
        }
    }

    // MARK: - State

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "1.0") (\(build ?? "1"))"
    }
}
