import SwiftUI

enum MessageStyle: String, Codable, CaseIterable, Identifiable {
    case bold
    case casual
    case formal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bold:
            "Bold"
        case .casual:
            "Casual"
        case .formal:
            "Formal"
        }
    }

    var font: Font {
        switch self {
        case .bold:
            .system(size: 20, weight: .bold, design: .rounded)
        case .casual:
            .system(size: 19, weight: .medium, design: .rounded)
        case .formal:
            .system(size: 20, weight: .semibold, design: .serif)
        }
    }

    var widgetFont: Font {
        switch self {
        case .bold:
            .system(size: 16, weight: .bold, design: .rounded)
        case .casual:
            .system(size: 15, weight: .medium, design: .rounded)
        case .formal:
            .system(size: 16, weight: .semibold, design: .serif)
        }
    }

    var foregroundHex: String {
        switch self {
        case .bold:
            "#FDE68A"
        case .casual:
            "#F9C469"
        case .formal:
            "#D9A35E"
        }
    }

    var backgroundHex: String {
        "#0A0A0A"
    }
}
