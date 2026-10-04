import SwiftUI

/// Typography scale for the host application.
///
/// Rounded sans for UI chrome, with the selected ``MessageStyle`` controlling
/// how message content itself is rendered.
enum AppTypography {
    static let screenTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 18, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .medium, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let button = Font.system(size: 15, weight: .bold, design: .rounded)
    static let subtleButton = Font.system(size: 15, weight: .semibold, design: .rounded)

    static let largeMetric = Font.system(size: 34, weight: .bold, design: .rounded)
}
