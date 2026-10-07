import SwiftUI

/// Central colour tokens for the Whisper design system: off-white text and a
/// deep-teal accent on a teal-charcoal surface stack.
///
/// The system is deliberately **gradient free**. Depth is produced by solid
/// layered surfaces, hairline borders, translucent glass fills and soft
/// shadows instead of linear gradients.
///
/// Every colour literal in the project lives here so the visual identity stays
/// identical between the host application and the widget extension.
enum AppColors {
    // MARK: Hex tokens (shared with `MessageStyle`, which is pure data)

    /// Screen background — the darkest step of the surface stack.
    static let surfaceHex = "#0D1110"
    /// Cards and grouped panels.
    static let surface1Hex = "#141A19"
    /// Rows, controls and input fields.
    static let surface2Hex = "#1B2221"
    /// Raised controls: selected chips, emphasised rows.
    static let surface3Hex = "#232B2A"
    /// Primary accent — teal used for every interactive highlight.
    static let accentHex = "#2DD4BF"
    /// Darker teal for filled accents that carry dark text.
    static let accentDeepHex = "#0F766E"
    /// Bright teal for high-emphasis message text on dark surfaces.
    static let accentBrightHex = "#5EEAD4"
    static let textPrimaryHex = "#F4F7F6"
    static let textMutedHex = "#8FA3A0"
    static let dangerHex = "#F87171"

    // MARK: Surface stack (solid, tonal, never gradient)

    static let surface = Color(hex: surfaceHex)
    static let surface1 = Color(hex: surface1Hex)
    static let surface2 = Color(hex: surface2Hex)
    static let surface3 = Color(hex: surface3Hex)

    // MARK: Accent & semantic

    static let accent = Color(hex: accentHex)
    static let accentDeep = Color(hex: accentDeepHex)
    static let accentBright = Color(hex: accentBrightHex)
    /// Accent tint used behind selected chips and badges.
    static let accentSoft = accent.opacity(0.14)
    static let textPrimary = Color(hex: textPrimaryHex)
    static let textMuted = Color(hex: textMutedHex)
    static let danger = Color(hex: dangerHex)
    static let dangerSoft = danger.opacity(0.12)

    // MARK: Borders, glass and depth

    /// Hairline border for cards and panels.
    static let border = Color.white.opacity(0.10)
    /// Softer hairline for rows nested inside cards.
    static let subtleBorder = Color.white.opacity(0.07)
    /// Slightly stronger edge used on glass surfaces so they read as a pane.
    static let glassBorder = Color.white.opacity(0.16)
    /// Translucent fill for glassmorphic surfaces.
    static let glassFill = Color.white.opacity(0.06)
    /// Single shadow token used for every elevated surface.
    static let shadowColor = Color.black.opacity(0.38)
}
