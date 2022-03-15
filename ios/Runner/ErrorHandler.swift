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

}
