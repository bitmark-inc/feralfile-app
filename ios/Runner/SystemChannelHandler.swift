//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Flutter
import Combine
import LibAuk

class SystemChannelHandler: NSObject {

    static let shared = SystemChannelHandler()
    private var cancelBag = Set<AnyCancellable>()


    func getiOSMigrationData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let url = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask)[0].appendingPathComponent("migration-db.json")

        guard let data = try? Data(contentsOf: url) else {
            result("")
            return
        }

        result(String(data: data, encoding: .utf8))

    }

    func cleariOSMigrationData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let url = FileManager.default.urls(for: .documentDirectory,
                                              in: .userDomainMask)[0].appendingPathComponent("migration-db.json")

        try? FileManager.default.removeItem(at: url)
        result([
            "error": 0,
            "msg": "cleariOSMigrationData success",
        ])
    }

    func getWalletUUIDsFromKeychain(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let personaUUIDs = scanKeychainPersonaUUIDs()
        result(personaUUIDs)
    }
    
    func removeKeychainItems(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any]
        let account = args["account"] as? String
        let service = args["service"] as? String
        let secClass = args["secClass"] as! CFTypeRef
        removeKeychainItems(account: account, service: service, secClass: secClass)
        result(nil)
    }
    
    private func removeKeychainItems(account: String? = nil, service: String? = nil, secClass: CFTypeRef = kSecClassGenericPassword) {
        var query: [String: Any] = [
            kSecClass as String: secClass,
            kSecReturnData as String: kCFBooleanTrue,
            kSecReturnAttributes as String : kCFBooleanTrue,
        ]
        
        if let account = account {
            query[kSecAttrAccount as String] = account
        }
        
        if let service = service {
            query[kSecAttrService as String] = service
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            logger.info("Keychain item(s) removed successfully.")
        } else if status == errSecItemNotFound {
            logger.info("Keychain item(s) not found.")
        } else {
            if let error: String = SecCopyErrorMessageString(status, nil) as String? {
                logger.error(error)
                    }

            logger.error("Error removing keychain item(s): \(status)")
        }
    }

    func scanKeychainPersonaUUIDs() -> [String] {
        var personaUUIDs = [String]()
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
                return []
            }

            for item in array {
                if let key = item[kSecAttrAccount as String] as? String, key.contains("seed") {
                    let personaUUIDString = key.replacingOccurrences(of: "persona.", with: "")
                        .replacingOccurrences(of: "_seed", with: "")

                    guard let personaUUID = UUID(uuidString: personaUUIDString) else {
                        continue
                    }

                    if (LibAuk.shared.storage(for: personaUUID).getETHAddress() != nil) {
                        personaUUIDs.append(personaUUIDString)
                    }

                }
            }
        }

        return personaUUIDs
    }
        
    func getDeviceUniqueID(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let keychain = Keychain()
        
        guard let data = keychain.getData(Constant.deviceIDKey, isSync: true),
              let id = String(data: data, encoding: .utf8) else {
                  let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                  keychain.set(deviceId.data(using: .utf8)!, forKey: Constant.deviceIDKey, isSync: true)

                  result(deviceId)
                  return
              }

        result(id)
    }
    
    func setPrimaryAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
                  let data = args["data"] as? String else {
                result(false)
                return
            }
        let keychain = Keychain()
        if keychain.set(data.data(using: .utf8)!, forKey: Constant.primaryAddressKey) {
                result(true)
            } else {
                result(false)
            }
    }
    
    func getPrimaryAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let keychain = Keychain()
        
        guard let data = keychain.getData(Constant.primaryAddressKey, isSync: true),
              let primaryAddress = String(data: data, encoding: .utf8) else {
                result("")
                return
              }

        result(primaryAddress)
    }
    
    func clearPrimaryAddress(call: FlutterMethodCall) {
        let keychain = Keychain()
        
        keychain.remove(key: Constant.primaryAddressKey, isSync: true)
        return
    }
    
    
}
