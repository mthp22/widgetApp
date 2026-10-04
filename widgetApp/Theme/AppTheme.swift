import SwiftUI

/// Shared layout constants and reusable surface styling derived from the
/// supplied artwork: dark rounded cards, hairline gold borders, restrained
/// gradients.
enum AppTheme {
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 14
    static let chipCornerRadius: CGFloat = 10
    static let contentPadding: CGFloat = 16
    static let controlPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 16
}

// MARK: - View modifiers

/// Grouped content surface: dark gradient panel with a hairline gold border.
struct WhisperCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius
    var padding: CGFloat = AppTheme.contentPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.panelGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
    }
}

/// Interactive surface used for list rows and chips.
struct WhisperRowModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.controlCornerRadius

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.controlPadding)
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
    }
}

extension View {
    /// Applies the standard card surface used across grouped content.
    func whisperCard(
        cornerRadius: CGFloat = AppTheme.cardCornerRadius,
        padding: CGFloat = AppTheme.contentPadding
    ) -> some View {
        modifier(WhisperCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Applies the standard interactive row surface.
    func whisperRow(cornerRadius: CGFloat = AppTheme.controlCornerRadius) -> some View {
        modifier(WhisperRowModifier(cornerRadius: cornerRadius))
    }

    /// Screen background: near-black surface with a warm gold glow.
    func whisperScreenBackground() -> some View {
        background {
            ZStack {
                AppColors.surface
                AppColors.backgroundGlow
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Button styles

/// Primary call to action: gold gradient, dark label.
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColors.surface)
            .background(AppColors.accentGradient.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

/// Secondary action: transparent surface with a hairline gold border.
struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subtleButton)
            .foregroundStyle(AppColors.textPrimary)
            .background(AppColors.card.opacity(configuration.isPressed ? 0.6 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
    }
}

/// Destructive action.
struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subtleButton)
            .foregroundStyle(AppColors.danger)
            .background(AppColors.card.opacity(configuration.isPressed ? 0.6 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                    .stroke(AppColors.danger.opacity(0.5), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
    }
}
