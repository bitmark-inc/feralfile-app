//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation

class Keychain {
    
    @discardableResult
    func set(_ data: Data, forKey: String, isSync: Bool = true) -> Bool {
        let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrSynchronizable as String: syncAttr!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
            kSecAttrAccount as String: forKey,
            kSecValueData as String: data
        ] as [String: Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == noErr {
            return true
        } else {
            return false
        }
    }

    func getData(_ key: String, isSync: Bool = true) -> Data? {
        let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: syncAttr!,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]

        var dataTypeRef: AnyObject?

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }

    @discardableResult
    func remove(key: String, isSync: Bool = true) -> Bool {
        let syncAttr = isSync ? kCFBooleanTrue : kCFBooleanFalse
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrSynchronizable as String: syncAttr!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
            kSecAttrAccount as String: key,
        ] as [String: Any]

        // Delete any existing items
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            return false
        } else {
            return true
        }

    }
}
