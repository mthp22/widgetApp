import SwiftUI

extension Color {
    /// Creates a color from a `#RRGGBB` hex string.
    ///
    /// Malformed input falls back to black rather than trapping, so a bad value
    /// in persisted styling data can never crash the app or the widget.
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var scanned: UInt64 = 0
        let didScan = Scanner(string: cleaned).scanHexInt64(&scanned)

        guard didScan, cleaned.count == 6 else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        let red = Double((scanned >> 16) & 0xFF) / 255
        let green = Double((scanned >> 8) & 0xFF) / 255
        let blue = Double(scanned & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}
