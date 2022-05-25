//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

//
//  ErrorHandler.swift
//  Runner
//
//  Created by Thuyên Trương on 10/03/2022.
//

import Foundation

enum AppError: String, Error {
    case pendingBeaconClient = "pendingBeaconClient"
    case incorrectData = "incorrectData"
    case aborted = "aborted"
    case invalidDeeplink = "invalidDeeplink"
}


struct ErrorHandler {
    static func handle(error: Error) -> [String: Any] {
        if let appError = error as? AppError {
            return [
                "error": 1,
                "reason": appError.rawValue,
            ]
        }

        return [
            "error": 1,
            "reason": error.localizedDescription,
        ]
    }

    static func flutterError(error: Error, _ defaultMessage: String) -> FlutterError {
        if let appError = error as? AppError {
            return FlutterError(code: appError.rawValue, message: defaultMessage, details: nil)
        }

        return FlutterError(code: defaultMessage, message: error.localizedDescription, details: nil)
    }

}
