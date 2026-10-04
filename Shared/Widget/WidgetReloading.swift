import Foundation

/// Requests a WidgetKit timeline refresh after application data changes.
///
/// This is the only mechanism the application uses to ask WidgetKit for new
/// content: iOS owns widget execution, so no timer or background task in the
/// app can render widget content by itself.
protocol WidgetReloading {
    func reloadAllTimelines()
}

/// No-op implementation, used where requesting a reload is meaningless (tests
/// and the widget extension itself, which only reads data).
struct NoOpWidgetReloader: WidgetReloading {
    func reloadAllTimelines() {}
}

#if canImport(WidgetKit)
import WidgetKit

/// Requests a refresh of every timeline of every widget kind.
struct WidgetCenterReloader: WidgetReloading {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif
