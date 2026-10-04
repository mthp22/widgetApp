import WidgetKit
import SwiftUI

/// The widget configuration registered with WidgetKit.
struct WhisperWidget: Widget {
    let kind: String = WhisperStorageConfiguration.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WhisperWidgetTimelineProvider()) { entry in
            WhisperWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Whisper")
        .description("Displays your next scheduled personal message on the Home Screen and Lock Screen.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}
