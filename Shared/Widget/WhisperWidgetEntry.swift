#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

struct WhisperWidgetEntry: TimelineEntry {
    let date: Date
    let text: String
    let style: MessageStyle
}
#endif
