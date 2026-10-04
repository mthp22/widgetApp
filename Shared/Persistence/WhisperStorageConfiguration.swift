import Foundation

/// Shared constants describing where and how messages are persisted and which
/// WidgetKit timeline kind belongs to this product.
enum WhisperStorageConfiguration {
    /// App Group shared by the application and the widget extension.
    /// Both targets declare this group in their entitlements, which is what
    /// gives the widget access to the app's persisted messages.
    static let appGroupIdentifier = "group.lm22.whisperwidget"

    /// File name of the JSON message library inside the shared container.
    static let fileName = "whisper_messages.json"

    /// WidgetKit kind registered by `WhisperWidget`.
    static let widgetKind = "WhisperWidget"

    /// Directory used when the App Group container is unavailable (for example
    /// in environments where App Groups are not provisioned).
    static let fallbackDirectoryName = "WhisperWidget"
}
