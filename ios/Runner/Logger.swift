//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

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
