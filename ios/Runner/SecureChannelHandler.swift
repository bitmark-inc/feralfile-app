//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Flutter
import Combine

class SecureChannelHandler: NSObject {

    static let shared = SecureChannelHandler()
    static var shouldShowSplash = true
    private var cancelBag = Set<AnyCancellable>()

    func setSecureFlag(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! NSDictionary
        let secure = args["secure"] as! Bool
        // Set the shouldShowSplash flag based on the 'secure' parameter
        SecureChannelHandler.shouldShowSplash = secure
        result(nil)

    }
}
