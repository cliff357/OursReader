//
//  SImplySendMiss.swift
//  SImplySendMiss
//
//  Created by Cliff Chan on 17/3/2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct SImplySendMissEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        GeometryReader { geometry in
                    VStack {
                        
                        // Show view size
                        Text("\(Int(geometry.size.width)) x \(Int(geometry.size.height))")
                            .font(.system(.title2, weight: .bold))
                        
                        // Show provider info
                        Text(entry.emoji)
                            .font(.footnote)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green)
                }
    }
}

struct SImplySendMiss: Widget {
    let kind: String = "SImplySendMiss"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                SImplySendMissEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SImplySendMissEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Hello Babe!")
        .description("Add me and tell me you are missing me")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,

            // Add Support to Lock Screen widgets
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

#Preview(as: .systemSmall) {
    SImplySendMiss()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
    SimpleEntry(date: .now, emoji: "22")
}
