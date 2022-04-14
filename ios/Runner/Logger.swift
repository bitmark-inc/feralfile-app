//
//  Logger.swift
//  Runner
//
//  Created by Ho Hien on 23/03/2022.
//

import Foundation
import Sentry

class Logger {
    static func error(_ message: String) {
        print(message)
        SentrySDK.capture(message: message)
    }

    static func info(_ message: String) {
        let crumb = Breadcrumb()
        crumb.level = SentryLevel.info
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb: crumb)
    }
}
