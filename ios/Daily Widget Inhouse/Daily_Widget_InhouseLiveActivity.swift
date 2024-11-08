//
//  Daily_Widget_InhouseLiveActivity.swift
//  Daily Widget Inhouse
//
//  Created by Anh Nguyen on 11/1/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Daily_Widget_InhouseAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Daily_Widget_InhouseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Daily_Widget_InhouseAttributes.self) { context in
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

extension Daily_Widget_InhouseAttributes {
    fileprivate static var preview: Daily_Widget_InhouseAttributes {
        Daily_Widget_InhouseAttributes(name: "World")
    }
}

extension Daily_Widget_InhouseAttributes.ContentState {
    fileprivate static var smiley: Daily_Widget_InhouseAttributes.ContentState {
        Daily_Widget_InhouseAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Daily_Widget_InhouseAttributes.ContentState {
         Daily_Widget_InhouseAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Daily_Widget_InhouseAttributes.preview) {
   Daily_Widget_InhouseLiveActivity()
} contentStates: {
    Daily_Widget_InhouseAttributes.ContentState.smiley
    Daily_Widget_InhouseAttributes.ContentState.starEyes
}
