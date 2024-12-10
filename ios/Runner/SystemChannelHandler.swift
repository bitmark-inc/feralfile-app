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
            return [:]
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
                   let seed = try? Seed(urString: dataString),
                   let mnemonicWords = try? Mnemonic.toMnemonic([UInt8](seed.data)){
                    mnemonicMap[personaUUIDString] = [seed.passphrase ?? ""] + mnemonicWords
                }
            }
        }
        
        return mnemonicMap
    }
        
    private func buildKeyAttr(prefix: String?, key: String) -> String {
        if let prefix = prefix {
            return "\(prefix)_\(key)"
        } else {
            return key
        }
    }
}
