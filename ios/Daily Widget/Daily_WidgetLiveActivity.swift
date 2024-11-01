//
//  Daily_WidgetLiveActivity.swift
//  Daily Widget
//
//  Created by Anh Nguyen on 10/31/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Daily_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Daily_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Daily_WidgetAttributes.self) { context in
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

extension Daily_WidgetAttributes {
    fileprivate static var preview: Daily_WidgetAttributes {
        Daily_WidgetAttributes(name: "World")
    }
}

extension Daily_WidgetAttributes.ContentState {
    fileprivate static var smiley: Daily_WidgetAttributes.ContentState {
        Daily_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Daily_WidgetAttributes.ContentState {
         Daily_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Daily_WidgetAttributes.preview) {
   Daily_WidgetLiveActivity()
} contentStates: {
    Daily_WidgetAttributes.ContentState.smiley
    Daily_WidgetAttributes.ContentState.starEyes
}
