//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Flutter
import Combine

class SocialRecoveryChannelHandler: NSObject {

    static let shared = SocialRecoveryChannelHandler()
    private var cancelBag = Set<AnyCancellable>()
    private let keychain = Keychain()

    func getContactDecks(call: FlutterMethodCall, result: @escaping FlutterResult) {
        var contactDecks = [String]()

        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue,
            kSecReturnData: kCFBooleanTrue,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecReturnAttributes as String : kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
        ]

        var dataTypeRef: AnyObject?
        let lastResultCode = withUnsafeMutablePointer(to: &dataTypeRef) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if lastResultCode == noErr {
            guard let array = dataTypeRef as? Array<Dictionary<String, Any>> else {
                return result([
                    "error": 0,
                    "result": [],
                ])
            }

            for item in array {
                if let key = item[kSecAttrAccount as String] as? String, key.contains("socialRecovery.contactDeck.") {
                    if let data = item[kSecValueData as String] as? Data,
                       let contactDeck = String(data: data, encoding: .utf8) {
                        contactDecks.append(contactDeck)
                    }
                }
            }
        }

        return result([
            "error": 0,
            "contactDecks": contactDecks,
        ])
    }

    func storeContactDeck(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let contactDeck: String = args["contactDeck"] as! String

        let isSuccess = keychain.set(contactDeck.data(using: .utf8)!, forKey: "socialRecovery.contactDeck." + uuid, isSync: true)

        if isSuccess {
            result([
                "error": 0,
                "msg": "storeContactDeck success",
            ])
        } else {
            result([
                "error": 1,
                "reason": "storeContactDeck failed",
            ])
        }
    }

    func deleteHelpingContactDecks(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: kCFBooleanTrue,
            kSecReturnData: kCFBooleanTrue,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecReturnAttributes as String : kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
        ]

        var dataTypeRef: AnyObject?
        let lastResultCode = withUnsafeMutablePointer(to: &dataTypeRef) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if lastResultCode == noErr {
            guard let array = dataTypeRef as? Array<Dictionary<String, Any>> else {
                return result([
                    "error": 0,
                    "message": "no ContactDecks to delete",
                ])
            }

            for item in array {
                if let key = item[kSecAttrAccount as String] as? String, key.contains("socialRecovery.contactDeck.") {
                    keychain.remove(key: key, isSync: true)
                }
            }
        }

        return result([
            "error": 0,
            "message": "delete ContactDecks successfully",
        ])
    }

}
