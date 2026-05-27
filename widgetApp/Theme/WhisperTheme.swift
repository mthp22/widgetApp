import SwiftUI

enum WhisperTheme {
    static let surface = Color(hex: "#0A0A0A")
    static let card = Color(hex: "#111111")
    static let accentLight = Color(hex: "#FDE68A")
    static let accentDark = Color(hex: "#B45309")
    static let textPrimary = Color(hex: "#F6E7C1")
    static let textMuted = Color(hex: "#CDAF74")

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentLight, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0E0E0E"), Color(hex: "#171717")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
