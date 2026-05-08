//
//  MyWidget.swift
//  widgetApp
//
//  Created by Leboreng Mathope on 2026/05/08.
//
import WidgetKit
import SwiftUI

struct LockedScreenIntent: Intent {
    var text: String = "Hello from Locked Screen!"
}

@main
struct LockWidgetIntentTimelineProvider: IntentTimelineProvider {
    typealias Entry = LockWidgetEntry
    
    func placeholder(in context: Context) -> Entry {
        return LockWidgetEntry(date: Date(), intent: LockedScreenIntent(text: "Placeholder Text"))
    }
    
    func getSnapshot(for configuration: LockedScreenIntent, in context: Context, completion: @escaping (LockWidgetEntry) -> Void) {
        let entry = LockWidgetEntry(date: Date(), intent: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: LockedScreenIntent, with entries: [LockWidgetEntry], in context: Context, completion: @escaping (IntentTimeline<Entry>) -> Void) {
        let nextDate = Calendar.current.date(byAdding:.minute, value: 60, to: entries.last?.date ?? Date())!
        
        let timeline = IntentTimeline(entries: entries + [LockWidgetEntry(date: nextDate, intent: configuration)], policy: .after(nextDate))
        
        completion(timeline)
    }
}

struct LockWidgetEntry: TimelineEntry {
    let date: Date
    let intent: LockedScreenIntent
    
    var body: some View {
        Text(intent.text)
    }
    
    var timelineData: [String]?
}

struct MyWidget: Widget {
    var body: some ConfigurableWidget {
        
        LockWidgetIntentTimelineProvider.Entry.dateProvider(in: .current, interval: 60) { date in
            [
                LockWidgetIntentTimelineProvider.Entry(date: date, intent: LockedScreenIntent(text: "Hello from Locked Screen!"))
            ]
        }
    }
}
