#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

struct WhisperWidget: Widget {
    let kind: String = WhisperStorageConfiguration.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WhisperWidgetEntryViewPalette()) { entry in
            WhisperWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("WhisperWidget")
        .description("Shows the next scheduled custom message.")
        .supportedFamilies([.accessoryInline, .accessoryRectangular])
    }
}
#endif
