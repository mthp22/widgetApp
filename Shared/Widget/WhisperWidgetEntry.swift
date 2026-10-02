import Foundation
import WidgetKit

/// One renderable state of the widget.
///
/// The entry carries only data that comes from the persisted message library —
/// there is no sample or hard-coded message anywhere in the widget target.
struct WhisperWidgetEntry: TimelineEntry, Equatable {
    /// What the widget should render.
    enum Content: Equatable {
        /// A persisted message, its schedule phase and the moment it took over.
        case message(Message, phase: MessageDisplay.Phase, effectiveAt: Date)
        /// The library is reachable but contains no displayable message.
        case empty
        /// The library could not be read (missing container or damaged data).
        case unavailable
    }

    let date: Date
    let content: Content
}

extension WhisperWidgetEntry {
    /// The message to render, if any.
    var message: Message? {
        if case let .message(message, _, _) = content {
            return message
        }
        return nil
    }

    /// Schedule phase of the rendered message, if any.
    var phase: MessageDisplay.Phase? {
        if case let .message(_, phase, _) = content {
            return phase
        }
        return nil
    }

    /// Short, user facing text used by compact Lock Screen presentations and
    /// by VoiceOver.
    var compactText: String {
        switch content {
        case let .message(message, _, _):
            message.normalizedContent
        case .empty:
            "No message scheduled"
        case .unavailable:
            "Messages unavailable"
        }
    }

    /// Secondary line describing when the message applies.
    var caption: String? {
        switch content {
        case let .message(_, phase, effectiveAt):
            switch phase {
            case .upcoming:
                "Scheduled \(effectiveAt.formatted(date: .omitted, time: .shortened))"
            case .active:
                nil
            }
        case .empty, .unavailable:
            nil
        }
    }

    static func empty(at date: Date) -> WhisperWidgetEntry {
        WhisperWidgetEntry(date: date, content: .empty)
    }

    static func unavailable(at date: Date) -> WhisperWidgetEntry {
        WhisperWidgetEntry(date: date, content: .unavailable)
    }
}
