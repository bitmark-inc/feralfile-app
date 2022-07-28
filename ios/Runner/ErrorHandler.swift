//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Flutter

enum AppError: String, Error {
    case pendingBeaconClient = "pendingBeaconClient"
    case incorrectData = "incorrectData"
    case aborted = "aborted"
    case invalidDeeplink = "invalidDeeplink"
}


struct ErrorHandler {
    static func handle(error: Error) -> FlutterError {
        if let appError = error as? AppError {
            return FlutterError(
                code: "1",
                message: appError.rawValue,
                details: nil
            )
        }

        return FlutterError(
            code: "1",
            message: error.localizedDescription,
            details: nil
        )
    }

    static func flutterError(error: Error, _ defaultMessage: String) -> FlutterError {
        if let appError = error as? AppError {
            return FlutterError(code: appError.rawValue, message: defaultMessage, details: nil)
        }

        return FlutterError(code: defaultMessage, message: error.localizedDescription, details: nil)
    }

}
