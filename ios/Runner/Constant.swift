//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation

struct Constant {
    static var appname: String {
        #if INHOUSE
        return "Feral File (Dev)";
        #else
        return "Feral File";
        #endif
    }
    
    static var isInhouse: Bool {
        #if INHOUSE
        return true;
        #else
        return false;
        #endif
    }

    static var keychainGroup: String = {
        #if INHOUSE
        return "Z5CE7A3A7N.com.bitmark.autonomy-wallet.inhouse.keychain"
        #else
        return "Z5CE7A3A7N.com.bitmark.autonomywallet.keychain"
        #endif
    }()
    
    static let deviceIDKey: String = "device_id_key"
    
    static let secureMainBundleIdentifiers: Set<String> = [
        "com.bitmark.autonomy-wallet",
        "com.bitmark.autonomy-wallet.inhouse",
    ]
    
    struct KeychainKey {
        static func personaPrefix(at uuid: UUID) -> String {
            "persona.\(uuid.uuidString)"
        }

        static let seed = "seed"
        static let ethInfoKey = "ethInfo"
        static let seedPublicData = "seedPublicData"
    }
}
