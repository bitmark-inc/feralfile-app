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

    func removeAllKeychainKeys(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let isSync: Bool = args["isSync"] as! Bool
        let query: NSDictionary = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: isSync,
            kSecAttrAccessGroup as String: Constant.keychainGroup,
        ]

        let status = SecItemDelete(query)
        if (status == errSecSuccess) {
            result([
                "error": 0,
                "msg": "removeAllKeychainKeys success",
            ])
        } else {
            result([
                "error": 1,
                "msg": "removeAllKeychainKeys failed \(status)",
            ])
        }

    }
}
