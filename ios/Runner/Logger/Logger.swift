//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Logging
import Foundation
//import Sentry

extension Logger {
    static let appLogURL = try! FileManager.default
        .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        .appendingPathComponent("app.log")
}

var logger: Logger = {
    do {
        let logFileURL = Logger.appLogURL
        let fileLogger = try FileLogging(to: logFileURL)

        LoggingSystem.bootstrap { label in
            let fileLogHandler = FileLogHandler(label: label, fileLogger: fileLogger)
            var consoleLogHandler = StreamLogHandler.standardOutput(label: label)
            consoleLogHandler.logLevel = .debug
            let handlers: [LogHandler] = [
                fileLogHandler,
                consoleLogHandler
            ]

           return MultiplexLogHandler(handlers)
        }
    } catch {
        fatalError(error.localizedDescription)
    }

    return Logger(label: "App")
}()

extension Logger {

    func info(_ message: String) {
        let logger = Logger.Message(stringLiteral: "(\(Thread.current.hash)) \(message)")
        self.info(logger)

        // Add sentry breadcrumb
//         let crumb = Breadcrumb()
//         crumb.level = SentryLevel.info
//        crumb.message = message
//         SentrySDK.addBreadcrumb(crumb: crumb)
    }

    func debug(_ message: String) {
        let logger = Logger.Message(stringLiteral: "(\(Thread.current.hash)) \(message)")
        self.debug(logger)
    }

    func error(_ message: String) {
        let logger = Logger.Message(stringLiteral: "(\(Thread.current.hash)) \(message)")
        self.error(logger)
//        SentrySDK.capture(message: message)
    }
}
