import SwiftUI

/// Central color tokens derived from the supplied `dev3.svg` artwork:
/// near-black surface (`#0A0A0A`), gold gradient (`#FDE68A → #B45309`).
///
/// Every color literal in the project lives here so the visual identity stays
/// consistent between the host application and the widget extension.
enum AppColors {
    // MARK: Hex tokens (shared with `MessageStyle`, which is pure data)

    static let surfaceHex = "#0A0A0A"
    static let cardHex = "#111111"
    static let accentLightHex = "#FDE68A"
    static let deepGoldHex = "#B45309"
    static let warmGoldHex = "#F9C469"
    static let textPrimaryHex = "#F6E7C1"
    static let textMutedHex = "#CDAF74"
    static let dangerHex = "#F87171"

    // MARK: Color tokens

    static let surface = Color(hex: surfaceHex)
    static let card = Color(hex: cardHex)
    static let accentLight = Color(hex: accentLightHex)
    static let deepGold = Color(hex: deepGoldHex)
    static let warmGold = Color(hex: warmGoldHex)
    static let textPrimary = Color(hex: textPrimaryHex)
    static let textMuted = Color(hex: textMutedHex)
    static let danger = Color(hex: dangerHex)

    /// Primary gold gradient used for emphasis (`#FDE68A → #B45309`).
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accentLight, deepGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Subtle dark surface gradient used behind grouped content.
    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#0E0E0E"), Color(hex: "#171717")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Warm radial glow used as background atmosphere.
    static var backgroundGlow: RadialGradient {
        RadialGradient(
            colors: [deepGold.opacity(0.22), .clear],
            center: .topTrailing,
            startRadius: 10,
            endRadius: 420
        )
    }

    /// Hairline border color for cards.
    static let border = deepGold.opacity(0.45)
    static let subtleBorder = deepGold.opacity(0.3)
}
