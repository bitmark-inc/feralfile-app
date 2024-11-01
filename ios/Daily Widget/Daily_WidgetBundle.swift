//
//  Daily_WidgetBundle.swift
//  Daily Widget
//
//  Created by Anh Nguyen on 10/31/24.
//

import WidgetKit
import SwiftUI

@main
struct Daily_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Daily_Widget()
        Daily_WidgetControl()
        Daily_WidgetLiveActivity()
    }
}
