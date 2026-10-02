import Foundation

protocol WidgetReloading {
    func reloadAllTimelines()
}

struct NoOpWidgetReloader: WidgetReloading {
    func reloadAllTimelines() { }
}

#if canImport(WidgetKit)
import WidgetKit

struct WidgetCenterReloader: WidgetReloading {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif
