//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Flutter
import Combine

class SystemChannelHandler: NSObject {
    
    static let shared = SystemChannelHandler()
    private var cancelBag = Set<AnyCancellable>()
    
    func exportMnemonicForAllPersonaUUIDs(call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            // Fetch all mnemonics mapped to persona UUIDs
            let mnemonicMap = try exportMnemonicForAllPersonaUUIDs()
            
            // Convert the result into a format Flutter can handle (e.g., a dictionary of String keys and array of strings)
            var resultMap: [String: Any] = [:]
            for (uuid, mnemonicWords) in mnemonicMap {
                resultMap[uuid] = mnemonicWords
            }
            
            // Send the result back to Flutter
            result(resultMap)
        } catch {
            // Handle any errors that occur and send the error message back to Flutter
            result(FlutterError(code: "EXPORT_MNEMONIC_ERROR",
                                message: "Failed to export mnemonics: \(error.localizedDescription)",
                                details: nil))
        }
    }
    
//    func removeKeychainItems(call: FlutterMethodCall, result: @escaping FlutterResult) {
//        let args = call.arguments as! [String: Any]
//        let account = args["account"] as? String
//        let service = args["service"] as? String
//        let secClass = args["secClass"] as! CFTypeRef
//        removeKeychainItems(account: account, service: service, secClass: secClass)
//        result(nil)
//    }
    
//    private func removeKeychainItems(account: String? = nil, service: String? = nil, secClass: CFTypeRef = kSecClassGenericPassword) {
//        var query: [String: Any] = [
//            kSecClass as String: secClass,
//            kSecReturnData as String: kCFBooleanTrue,
//            kSecReturnAttributes as String : kCFBooleanTrue,
//        ]
//        
//        if let account = account {
//            query[kSecAttrAccount as String] = account
//        }
//        
//        if let service = service {
//            query[kSecAttrService as String] = service
//        }
//        
//        let status = SecItemDelete(query as CFDictionary)
//        
//        if status == errSecSuccess {
//            logger.info("Keychain item(s) removed successfully.")
//        } else if status == errSecItemNotFound {
//            logger.info("Keychain item(s) not found.")
//        } else {
//            if let error: String = SecCopyErrorMessageString(status, nil) as String? {
//                logger.error(error)
//            }
//            
//            logger.error("Error removing keychain item(s): \(status)")
//        }
//    }
    
    func exportMnemonicForAllPersonaUUIDs() throws -> [String: [String]] {
        // define map: key is uuid, value is list from passphrase at index 0, the next are mnenmonic words
        var mnemonicMap = [String: [String]]()

        
        // querry all keychain items
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
        let status = withUnsafeMutablePointer(to: &dataTypeRef) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        guard status == noErr else {
            throw LibAukError.other(reason: "Keychain query failed with status: \(status)")
        }
        
            guard let array = dataTypeRef as? Array<Dictionary<String, Any>> else {
                return []
            }
            
            for item in array {
                // filter seed keychain by check if have `seed` in key: personna.uuid_seed
                if let key = item[kSecAttrAccount as String] as? String, key.contains("seed") {
                    
                    // get uuid
                    let personaUUIDString = key
                        .replacingOccurrences(of: "persona.", with: "")
                        .replacingOccurrences(of: "_seed", with: "")
                    
                    if let data = item[kSecValueData as String] as? Data,
                       let dataString = String(data: data, encoding: .utf8),
                       let seed = try? Seed(urString: dataString) {
                        var mnemonicWords = [seed.passphrase ?? ""]
                        mnemonicWords.append(contentsOf: Keys.mnemonic(seed.data))
                        mnemonicMap[personaUUIDString] = mnemonicWords
                    }
                }
            }
        
        
        return mnenmonicMap
    }
        
    private func buildKeyAttr(prefix: String?, key: String) -> String {
        if let prefix = prefix {
            return "\(prefix)_\(key)"
        } else {
            return key
        }
    }
}


class Key {
    static func mnemonic(_ entropy: Data) -> BIP39Mnemonic? {
        let bip39entropy = BIP39Mnemonic.Entropy(entropy)

        return try? BIP39Mnemonic(entropy: bip39entropy)
    }
}
