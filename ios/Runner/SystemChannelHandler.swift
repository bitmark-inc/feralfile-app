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
        let personaUUIDs = scanKeychainPersonaUUIDs(isSync: false)
        result(personaUUIDs)
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

    func migrateAccountsFromV0ToV1(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let personaUUIDs = scanKeychainPersonaUUIDs(isSync: true)

        let executionPublishers = personaUUIDs.compactMap { uuid in
            return LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
                .migrateV0ToV1()
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(executionPublishers)
            .collect()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "migrateAccountsFromV0ToV1 success",
                ])
            })
            .store(in: &cancelBag)
    }
}

fileprivate extension SystemChannelHandler {

    func scanKeychainPersonaUUIDs(isSync: Bool) -> [String] {
        var personaUUIDs = [String: Seed]()
        let query: NSDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrSynchronizable: isSync ? kCFBooleanTrue : kCFBooleanFalse,
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
                    if let seedUR = (item[kSecValueData as String] as? Data)?.utf8,
                       let seed = try? Seed(urString: seedUR) {
                        personaUUIDs[personaUUIDString] = seed
                    }
                }
            }
        }

        return personaUUIDs.sorted(by: { $0.value.creationDate ?? Date() < $1.value.creationDate ?? Date() })
            .map(\.key)
    }
        

}
