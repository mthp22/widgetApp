import SwiftUI

/// Layout constants plus the surface, glass and button vocabulary of the
/// design system.
///
/// The system is gradient free: panels are solid tonal steps from
/// ``AppColors``, glass surfaces are translucent material with a hairline
/// border, and depth comes from one shared soft-shadow token.
enum AppTheme {
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 14
    static let chipCornerRadius: CGFloat = 12
    static let glassCornerRadius: CGFloat = 24
    static let contentPadding: CGFloat = 16
    static let controlPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 16
    /// Offset of the shared card shadow.
    static let shadowOffset: CGFloat = 10
}

// MARK: - Surfaces

/// Grouped content surface: one solid tonal step above the screen background,
/// a hairline border and the shared soft shadow.
struct WhisperCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius
    var padding: CGFloat = AppTheme.contentPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.surface1)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
            .shadow(
                color: AppColors.shadowColor,
                radius: 16,
                x: 0,
                y: AppTheme.shadowOffset
            )
    }
}

/// Interactive surface used for rows nested inside cards.
struct WhisperRowModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.controlCornerRadius

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.controlPadding)
            .background(AppColors.surface2)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
    }
}

/// Translucent, blurred pane with a hairline edge — used for floating or
/// emphasised elements such as the widget card, badges and toolbars.
struct WhisperGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.glassCornerRadius
    var padding: CGFloat = AppTheme.contentPadding

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                shape.fill(AppColors.glassFill)
            }
            .overlay {
                shape.stroke(AppColors.glassBorder, lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(
                color: AppColors.shadowColor,
                radius: 18,
                x: 0,
                y: AppTheme.shadowOffset
            )
    }
}

// MARK: - Press feedback

/// Spring-based press feedback for a surface whose pressed state is already
/// known — used by the button styles so Reduced Motion is honoured.
struct WhisperPressEffectModifier: ViewModifier {
    let isPressed: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed && !reduceMotion ? AppMotion.pressScale : 1)
            .opacity(isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : AppMotion.snappy, value: isPressed)
    }
}

/// Press-only button style: keeps the label exactly as authored and adds the
/// shared scale/opacity response. Used where a full surface style would fight
/// the surrounding list layout (day chips, toolbar actions).
struct WhisperPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .whisperPressEffect(isPressed: configuration.isPressed)
    }
}

extension ButtonStyle where Self == WhisperPressButtonStyle {
    /// `.buttonStyle(.whisperPress)`
    static var whisperPress: WhisperPressButtonStyle { WhisperPressButtonStyle() }
}

// MARK: - View modifiers

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

    /// Applies the translucent glass surface used for floating elements.
    func whisperGlass(
        cornerRadius: CGFloat = AppTheme.glassCornerRadius,
        padding: CGFloat = AppTheme.contentPadding
    ) -> some View {
        modifier(WhisperGlassModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// Applies press feedback when the pressed state comes from a button.
    func whisperPressEffect(isPressed: Bool) -> some View {
        modifier(WhisperPressEffectModifier(isPressed: isPressed))
    }

    /// Flat screen background: solid base tone, no gradients or glows.
    func whisperScreenBackground() -> some View {
        background(AppColors.surface.ignoresSafeArea())
    }

    /// Material toolbar background shared by every screen.
    ///
    /// The background is requested but its visibility stays automatic, which
    /// lets iOS decide when the glass sits behind scrolling content — forcing
    /// it visible hides the large navigation title on iOS 26.
    func whisperToolbarBackground() -> some View {
        toolbarBackground(.ultraThinMaterial, for: .navigationBar)
    }
}

// MARK: - Button styles

/// Primary call to action: solid teal fill, dark label, spring press.
struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColors.surface)
            .background(AppColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
            .whisperPressEffect(isPressed: configuration.isPressed)
    }
}

/// Secondary action: raised solid surface with a hairline border.
struct SubtleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subtleButton)
            .foregroundStyle(AppColors.textPrimary)
            .background(configuration.isPressed ? AppColors.surface3 : AppColors.surface2)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                    .stroke(AppColors.subtleBorder, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
            .whisperPressEffect(isPressed: configuration.isPressed)
    }
}

/// Destructive action: danger text on a raised surface with a danger hairline.
struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.subtleButton)
            .foregroundStyle(AppColors.danger)
            .background(configuration.isPressed ? AppColors.dangerSoft : AppColors.surface2)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                    .stroke(AppColors.danger.opacity(0.45), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
            .whisperPressEffect(isPressed: configuration.isPressed)
    }
}
