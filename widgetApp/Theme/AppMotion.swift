import SwiftUI

/// Motion tokens for the whole application.
///
/// Every animation in the app is expressed in terms of these constants so
/// timing and feel stay consistent — the goal is the quiet, springy responsiveness
/// of a Framer Motion composition, not decoration.
///
/// All tokens are disabled automatically when the user asks for Reduced Motion,
/// which each consuming view checks through `\.accessibilityReduceMotion`.
enum AppMotion {
    // MARK: Springs

    /// Default spring for layout changes (cards, panels, navigation).
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.82)

    /// Snappier spring for direct manipulation: presses, toggles, selection.
    static let snappy = Animation.spring(response: 0.26, dampingFraction: 0.74)

    /// Gentler spring for entrance choreography.
    static let entrance = Animation.spring(response: 0.42, dampingFraction: 0.86)

    // MARK: Easing

    /// Short ease-out used for opacity-only changes.
    static let quick = Animation.easeOut(duration: 0.18)

    /// Stagger step applied between list rows as they enter.
    static let stagger: TimeInterval = 0.03
    /// Upper bound on the stagger so long lists never feel delayed.
    static let staggerCap = 8

    // MARK: Scale

    /// Scale applied to a surface while it is pressed.
    static let pressScale: CGFloat = 0.97
    /// Scale used by cards as they enter the screen.
    static let entranceScale: CGFloat = 0.98
}

// MARK: - Transitions

extension AnyTransition {
    /// Rows and cards sliding up a few points while fading in.
    static var whisperRise: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }

    /// Cards settling into place with a very small scale change.
    static var whisperSettle: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: AppMotion.entranceScale)),
            removal: .opacity
        )
    }
}
