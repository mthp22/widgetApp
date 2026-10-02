import WidgetKit
import SwiftUI

/// Supplies WidgetKit with entries built from the shared message library.
///
/// This type only translates `WidgetDataSource` output into WidgetKit's
/// callback API — it owns no state and never touches the application UI.
struct WhisperWidgetTimelineProvider: TimelineProvider {
    private let dataSource: WidgetDataSource

    init(dataSource: WidgetDataSource = WidgetDataSource()) {
        self.dataSource = dataSource
    }

    /// Gallery previews use the genuine empty state, never fabricated content.
    func placeholder(in context: Context) -> WhisperWidgetEntry {
        .empty(at: Date())
    }

    /// Snapshots read the real persisted library, so the widget gallery shows
    /// exactly what the user has stored.
    func getSnapshot(in context: Context, completion: @escaping (WhisperWidgetEntry) -> Void) {
        completion(dataSource.currentEntry(at: Date()))
    }

    /// Builds a timeline covering the upcoming schedule changes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<WhisperWidgetEntry>) -> Void) {
        let now = Date()
        let widgetTimeline = dataSource.timeline(from: now)
        completion(Timeline(entries: widgetTimeline.entries, policy: widgetTimeline.policy))
    }
}
