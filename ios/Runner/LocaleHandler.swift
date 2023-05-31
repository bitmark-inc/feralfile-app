//
//  LocaleMeasurementHandle.swift
//  Runner
//
//  Created by Le Phuoc on 31/05/2023.
//

import Foundation

class LocaleHandler {

    static let shared = LocaleHandler()
    
    func getMeasurementSystem(call: FlutterMethodCall, result: @escaping FlutterResult) {
        var locale: String?
        if #available(iOS 16.0, *) {
            locale = Locale.current.measurementSystem.identifier
        }
        
        result([
            "error": 0,
            "data": locale
        ])
    }
}
