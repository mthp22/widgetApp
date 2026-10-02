import SwiftUI

/// The single authoritative description of how a message is presented.
///
/// Both the host application and the widget extension read these mappings, so
/// visual styling is defined exactly once instead of being duplicated in views.
enum MessageStyle: String, Codable, CaseIterable, Identifiable, Hashable {
    case bold
    case casual
    case formal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bold: "Bold"
        case .casual: "Casual"
        case .formal: "Formal"
        }
    }

    var accessibilityDescription: String {
        switch self {
        case .bold: "Bold, rounded, high emphasis"
        case .casual: "Casual, rounded, medium emphasis"
        case .formal: "Formal, serif, refined emphasis"
        }
    }

    // MARK: Typography

    /// Font used inside the host application (previews, list rows, detail).
    var font: Font {
        switch self {
        case .bold: .system(size: 20, weight: .bold, design: .rounded)
        case .casual: .system(size: 19, weight: .medium, design: .rounded)
        case .formal: .system(size: 20, weight: .semibold, design: .serif)
        }
    }

    /// Scaled font used inside widgets, where space is limited.
    var widgetFont: Font {
        switch self {
        case .bold: .system(size: 16, weight: .bold, design: .rounded)
        case .casual: .system(size: 15, weight: .medium, design: .rounded)
        case .formal: .system(size: 16, weight: .semibold, design: .serif)
        }
    }

    // MARK: Color

    /// Hex color of the rendered message text.
    var foregroundHex: String {
        switch self {
        case .bold: AppColors.accentLightHex
        case .casual: AppColors.warmGoldHex
        case .formal: AppColors.deepGoldHex
        }
    }

    /// Hex color of the surface behind the rendered message text.
    var backgroundHex: String {
        AppColors.surfaceHex
    }

    var foregroundColor: Color {
        Color(hex: foregroundHex)
    }

    var backgroundColor: Color {
        Color(hex: backgroundHex)
    }
}
