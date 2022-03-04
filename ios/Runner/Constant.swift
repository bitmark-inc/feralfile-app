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
}
