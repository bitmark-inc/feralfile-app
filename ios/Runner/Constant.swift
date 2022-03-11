//
//  Constant.swift
//  Runner
//
//  Created by Thuyên Trương on 04/03/2022.
//

import Foundation

struct Constant {
    static var appname: String {
        #if INHOUSE
        return "Autonomy (Dev)";
        #else
        return "Autonomy";
        #endif
    }

    static var keychainGroup: String = {
        #if INHOUSE
        return "A52M7AQ8B2.com.bitmark.autonomy.inhouse.keychain"
        #else
        return "Z5CE7A3A7N.com.bitmark.autonomywallet.keychain"
        #endif
    }()
    
    static let deviceIDKey: String = "device_id_key"
}
