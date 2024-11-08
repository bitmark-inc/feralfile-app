//
//  Daily_Widget_InhouseBundle.swift
//  Daily Widget Inhouse
//
//  Created by Anh Nguyen on 11/1/24.
//

import WidgetKit
import SwiftUI

@main
struct Daily_Widget_InhouseBundle: WidgetBundle {
    var body: some Widget {
        Daily_Widget_Inhouse()
        Daily_Widget_InhouseControl()
        Daily_Widget_InhouseLiveActivity()
    }
}
