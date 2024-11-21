//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation

struct Constant {
    static var appname: String {
        if isInhouse() {
            return "Feral File (Dev)"
        } else {
            return "Feral File"
        }
    }

    static var keychainGroup: String {
        if isInhouse() {
            return "Z5CE7A3A7N.com.bitmark.autonomy-wallet.inhouse.keychain"
        } else {
            return "Z5CE7A3A7N.com.bitmark.autonomywallet.keychain"
        }
    }
    
    static let deviceIDKey: String = "device_id_key"

    static let secureMainBundleIdentifiers: Set<String> = [
        "com.bitmark.autonomywallet",
        "com.bitmark.autonomy-wallet.inhouse",
    ]

    static func isInhouse() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "Unknown"
        return bundleIdentifier.contains("inhouse")
    }
    static let primaryAddressKey: String = "primary_address_key"
    static let jwtKey: String = "jwt_key"
    static let userIdKey: String = "user_id_key"
    static let didRegisterPasskeys = "did_register_passkeys"
}
