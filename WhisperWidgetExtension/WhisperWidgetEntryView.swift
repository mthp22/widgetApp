#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

struct WhisperWidgetEntryView: View {
    let entry: WhisperWidgetEntry

    var body: some View {
        Text(entry.text)
            .font(entry.style.widgetFont)
            .foregroundColor(Color(hex: entry.style.foregroundHex))
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(8)
            .containerBackground(Color(hex: entry.style.backgroundHex), for: .widget)
    }
}
#endif
