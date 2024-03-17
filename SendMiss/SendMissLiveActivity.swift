//
//  SendMissLiveActivity.swift
//  SendMiss
//
//  Created by Cliff Chan on 17/3/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SendMissAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SendMissLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SendMissAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SendMissAttributes {
    fileprivate static var preview: SendMissAttributes {
        SendMissAttributes(name: "World")
    }
}

extension SendMissAttributes.ContentState {
    fileprivate static var smiley: SendMissAttributes.ContentState {
        SendMissAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SendMissAttributes.ContentState {
         SendMissAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SendMissAttributes.preview) {
   SendMissLiveActivity()
} contentStates: {
    SendMissAttributes.ContentState.smiley
    SendMissAttributes.ContentState.starEyes
}
