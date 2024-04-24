//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import LibAuk
import BigInt
import Web3
import KukaiCoreSwift
import Combine

class LibAukChannelHandler {

    static let shared = LibAukChannelHandler()
    private var cancelBag = Set<AnyCancellable>()

    private func isBiometricTurnedOn() -> Bool {
        // Retrieve the biometric data from Keychain
        let biometricData = UserDefaults.standard.bool(forKey: "flutter.device_passcode")
        if biometricData == true {
            // Check the value of the biometric data
            return biometricData
        } else {
            // If biometric data is not found in Keychain, consider it turned off
            return false
        }
    }


    private func migrateKeychainV1() {
        let keychain = Keychain()
        let allEthInfoKeychainItems = keychain.getAllKeychainItem { (item: [String: Any]) -> Bool in
            if let key = item[kSecAttrAccount as String] as? String {
                return key.contains("ethInfo")
            }
            return false
        }
        for item in allEthInfoKeychainItems ?? [] {
            if let uuidString = item["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                LibAuk.shared.storage(for: uuid).migrateFromKeyInfo2SeedPublicData()
            }
        }
    }

    private func migrateKeychain() {
        migrateKeychainV1()
    }

    private func setBiometric(isEnable: Bool) {
        // Save the biometric data to UserDefaults
        UserDefaults.standard.set(isEnable, forKey: "flutter.device_passcode")
    }

    func createKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let passphrase: String = (args["passphrase"] as? String) ?? ""
        let name: String = (args["name"] as? String) ?? ""
        let isBioMetricTurnedOn = isBiometricTurnedOn()

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).createKey(passphrase: passphrase ,name: name, isPrivate: isBioMetricTurnedOn)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "createKey success",
                ])
            })
            .store(in: &cancelBag)
    }

    func importKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let passphrase: String = (args["passphrase"] as? String) ?? ""
        let name: String = (args["name"] as? String) ?? ""
        let words: String = (args["words"] as? String) ?? ""
        let dateInMili: Double? = args["date"] as? Double

        let date = dateInMili != nil ? Date(timeIntervalSince1970: dateInMili!) : nil
        let wordsArray = words.components(separatedBy: " ")
        let isBioMetricTurnedOn = isBiometricTurnedOn()

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .importKey(words: wordsArray, passphrase: passphrase, name: name, creationDate:date, isPrivate: isBioMetricTurnedOn)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "importKey success",
                ])
            })
            .store(in: &cancelBag)
    }

    func calculateFirstEthAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let passphrase: String = (args["passphrase"] as? String) ?? ""
        let words: String = (args["words"] as? String) ?? ""
        let wordsArray = words.components(separatedBy: " ")
        LibAuk.shared.calculateEthFirstAddress(words: wordsArray, passphrase: passphrase)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { address in
                result([
                    "error": 0,
                    "data": address,
                ])
            })
            .store(in: &cancelBag)
    }

    func isWalletCreated(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).isWalletCreated()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { isCreated in
                result([
                    "error": 0,
                    "data": isCreated,
                ])
            })
            .store(in: &cancelBag)
    }

    func getName(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        let address = LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getName() ?? ""

        result([
            "error": 0,
            "data": address
        ])
    }

    func getAccountDID(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .getAccountDID()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { (accountDID) in
                result([
                    "error": 0,
                    "data": accountDID,
                ])
            })
            .store(in: &cancelBag)
    }

    func getAccountDIDSignature(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message: String = args["message"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .getAccountDIDSignature(message: message)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (signature) in
                result([
                    "error": 0,
                    "data": signature,
                ])
            })
            .store(in: &cancelBag)
    }

    func getETHAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        let address = LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getETHAddress() ?? ""

        result([
            "error": 0,
            "data": address
        ])
    }

    func getETHAddressWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getETHAddressWithIndex(index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { address in
                result([
                    "error": 0,
                    "data":address,
                ])
            })
            .store(in: &cancelBag)
    }

    func signPersonalMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSign(message: [UInt8](message.data.personalSignedMessageData))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "data": "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16),
                ])
            })
            .store(in: &cancelBag)
    }

    func signPersonalMessageWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignWithIndex(message: [UInt8](message.data.personalSignedMessageData), index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "data": "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16),
                ])
            })
            .store(in: &cancelBag)
    }

    func signMessageWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignWithIndex(message: [UInt8](message.data), index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "data": "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16),
                ])
            })
            .store(in: &cancelBag)
    }

    func signMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSign(message: [UInt8](message.data))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "data": "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16),
                ])
            })
            .store(in: &cancelBag)
    }

    func signTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let nonce: String = args["nonce"] as? String ?? "0"
        let gasPrice: String = args["gasPrice"] as? String ?? "0"
        let gasLimit: String = args["gasLimit"] as? String ?? "0"
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? "0"
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0

        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(nonce, radix: 10) ?? BigUInt.zero),
            gasPrice: EthereumQuantity(quantity: BigUInt(gasPrice, radix: 10) ?? BigUInt.zero),
            gasLimit: EthereumQuantity(quantity: BigUInt(gasLimit, radix: 10) ?? BigUInt.zero),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(value, radix: 10) ?? BigUInt.zero),
            data: try! EthereumData.string(data))


        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignTransaction(transaction: transaction, chainId: EthereumQuantity(quantity: BigUInt(chainId)))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { signedTx in
                let bytes: [UInt8] = try! RLPEncoder().encode(signedTx.rlp())
                result([
                    "error": 0,
                    "data": Data(bytes),
                ])
            })
            .store(in: &cancelBag)
    }

    func signTransactionWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let nonce: String = args["nonce"] as? String ?? "0"
        let gasPrice: String = args["gasPrice"] as? String ?? "0"
        let gasLimit: String = args["gasLimit"] as? String ?? "0"
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? "0"
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0
        let index: Int = args["index"] as? Int ?? 0

        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(nonce, radix: 10) ?? BigUInt.zero),
            gasPrice: EthereumQuantity(quantity: BigUInt(gasPrice, radix: 10) ?? BigUInt.zero),
            gasLimit: EthereumQuantity(quantity: BigUInt(gasLimit, radix: 10) ?? BigUInt.zero),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(value, radix: 10) ?? BigUInt.zero),
            data: try! EthereumData.string(data))


        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignTransactionWithIndex(transaction: transaction, chainId: EthereumQuantity(quantity: BigUInt(chainId)), index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { signedTx in
                let bytes: [UInt8] = try! RLPEncoder().encode(signedTx.rlp())
                result([
                    "error": 0,
                    "data": Data(bytes),
                ])
            })
            .store(in: &cancelBag)
    }

    func signTransaction1559(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let nonce: String = args["nonce"] as? String ?? "0"
        let gasLimit: String = args["gasLimit"] as? String ?? "0"
        let maxPriorityFeePerGas: String = args["maxPriorityFeePerGas"] as? String ?? "0"
        let maxFeePerGas: String = args["maxFeePerGas"] as? String ?? "0"
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? "0"
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0

        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(nonce, radix: 10) ?? BigUInt.zero),
            maxFeePerGas: EthereumQuantity(quantity: BigUInt(maxFeePerGas, radix: 10) ?? BigUInt.zero),
            maxPriorityFeePerGas: EthereumQuantity(quantity: BigUInt(maxPriorityFeePerGas, radix: 10) ?? BigUInt.zero),
            gasLimit: EthereumQuantity(quantity: BigUInt(gasLimit, radix: 10) ?? BigUInt.zero),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(value, radix: 10) ?? BigUInt.zero),
            data: try! EthereumData.string(data),
            transactionType: .eip1559
        )


        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignTransaction(transaction: transaction, chainId: EthereumQuantity(quantity: BigUInt(chainId)))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { signedTx in
                result([
                    "error": 0,
                    "data": try! signedTx.rawTransaction().bytes.data,
                ])
            })
            .store(in: &cancelBag)
    }

    func signTransaction1559WithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let nonce: String = args["nonce"] as? String ?? "0"
        let gasLimit: String = args["gasLimit"] as? String ?? "0"
        let maxPriorityFeePerGas: String = args["maxPriorityFeePerGas"] as? String ?? "0"
        let maxFeePerGas: String = args["maxFeePerGas"] as? String ?? "0"
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? "0"
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0
        let index: Int = args["index"] as? Int ?? 0

        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(nonce, radix: 10) ?? BigUInt.zero),
            maxFeePerGas: EthereumQuantity(quantity: BigUInt(maxFeePerGas, radix: 10) ?? BigUInt.zero),
            maxPriorityFeePerGas: EthereumQuantity(quantity: BigUInt(maxPriorityFeePerGas, radix: 10) ?? BigUInt.zero),
            gasLimit: EthereumQuantity(quantity: BigUInt(gasLimit, radix: 10) ?? BigUInt.zero),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(value, radix: 10) ?? BigUInt.zero),
            data: try! EthereumData.string(data),
            transactionType: .eip1559
        )


        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .ethSignTransactionWithIndex(transaction: transaction, chainId: EthereumQuantity(quantity: BigUInt(chainId)), index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { signedTx in
                result([
                    "error": 0,
                    "data": try! signedTx.rawTransaction().bytes.data,
                ])
            })
            .store(in: &cancelBag)
    }

    func exportMnemonicWords(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).exportMnemonicWords()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { words in
                result([
                    "error": 0,
                    "data": words.joined(separator: " "),
                ])
            })
            .store(in: &cancelBag)
    }

    func exportMnemonicPassphrase(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).exportMnemonicPassphrase()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { passphrase in
                result([
                    "error": 0,
                    "data": passphrase,
                ])
            })
            .store(in: &cancelBag)
    }
    
    func getTezosPublicKeyWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getTezosPublicKeyWithIndex(index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { publicKey in
                result([
                    "error": 0,
                    "data": publicKey,
                ])
            })
            .store(in: &cancelBag)
    }

    func tezosSign(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .tezosSign(message: message.data)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { bytes in
                result([
                    "error": 0,
                    "data": FlutterStandardTypedData(bytes: Data(bytes)),
                ])
            })
            .store(in: &cancelBag)
    }

    func tezosSignWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .tezosSignWithIndex(message: message.data, index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { bytes in
                result([
                    "error": 0,
                    "data": FlutterStandardTypedData(bytes: Data(bytes)),
                ])
            })
            .store(in: &cancelBag)
    }

    func tezosSignTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let forgedHex = args["forgedHex"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .tezosSignTransaction(forgedHex: forgedHex)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { bytes in
                result([
                    "error": 0,
                    "data": FlutterStandardTypedData(bytes: Data(bytes)),
                ])
            })
            .store(in: &cancelBag)
    }

    func tezosSignTransactionWithIndex(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let forgedHex = args["forgedHex"] as! String
        let index: Int = args["index"] as? Int ?? 0

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .tezosSignTransactionWithIndex(forgedHex: forgedHex, index: index)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { bytes in
                result([
                    "error": 0,
                    "data": FlutterStandardTypedData(bytes: Data(bytes)),
                ])
            })
            .store(in: &cancelBag)
    }

    func encryptFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let inputPath: String = args["inputPath"] as! String
        let outputPath: String = args["outputPath"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .encryptFile(inputPath: inputPath, outputPath: outputPath)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { output in
                result([
                    "error": 0,
                    "data": output,
                ])
            })
            .store(in: &cancelBag)
    }

    func decryptFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let inputPath: String = args["inputPath"] as! String
        let outputPath: String = args["outputPath"] as! String
        let usingLegacy: Bool = args["usingLegacy"] as? Bool ?? false

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .decryptFile(inputPath: inputPath, outputPath: outputPath, usingLegacy: usingLegacy)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { output in
                result([
                    "error": 0,
                    "data": output,
                ])
            })
            .store(in: &cancelBag)
    }


    func removeKeys(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).removeKeys()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "removeKey success",
                ])
            })
            .store(in: &cancelBag)

    }

    func migrateSeed(item: Dictionary<String, Any>, isBiometricEnable: Bool) {
        if let data = item[kSecValueData as String] as? Data,
           let seedUR = String(data: data, encoding: .utf8) {
            // Assuming Seed is a custom type and Seed initializer is available
            if let seed = try? Seed(urString: seedUR) {
                // Extract personaUUID from key and add to dictionary
                if let key = item[kSecAttrAccount as String] as? String, key.contains("_seed") {
                    let personaUUIDString = key.replacingOccurrences(of: "persona.", with: "")
                                                 .replacingOccurrences(of: "_seed", with: "")
                    if let personaUUID = UUID(uuidString: personaUUIDString) {
                        let storage = LibAuk.shared.storage(for: personaUUID)
                        storage.setSeed(seed: seed, isPrivate: isBiometricEnable).sink { (completion) in
                            // TODO
                        } receiveValue: { _ in
                            // TODO
                        }.store(in: &cancelBag)

                    }
                }
            } else {
                // Handle error when parsing Seed
                print("Failed to parse Seed from: \(seedUR)")
            }
        } else {
            // Handle error when decoding data to UTF-8 string
            print("Failed to decode data to UTF-8 string: \(item)")
        }
    }

    func toggleBiometric(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let isBiometricEnable = args["isEnable"] as! Bool

        let keychainItems = Keychain().getAllKeychainItem { (item: [String: Any]) -> Bool in
            return true
        }
        self.setBiometric(isEnable: isBiometricEnable)

        var seedItems: [UUID: Seed] = [:] // Dictionary to store personaUUID: Seed pairs

        if let items = keychainItems {
            for item in items {
                migrateSeed(item: item, isBiometricEnable: isBiometricEnable)
            }
        }

        result(["error": 0,
                "data": true,
        ])
    }

    func isBiometricTurnedOn(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Retrieve the biometric data from Keychain
        let isTurnedOn = isBiometricTurnedOn()
        result([
            "error": 0,
            "data": isTurnedOn
        ])
    }
    
    func migrate(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let allItems = Keychain().getAllKeychainItem { item in
            return true
        }
        if let items = allItems {
            for item in items {
                let account = item[kSecAttrAccount as! String]as! String
                Keychain().remove(key: account)
            }
        }
        let allEthInfoKeychainItems = Keychain().getAllKeychainItem { item in
            let account = item[kSecAttrAccount as! String]as! String
            return account.contains("ethInfo")
        }
        if let items = allEthInfoKeychainItems {
            for item in items {
                if let account = item[kSecAttrAccount as! String] as? String {
                    let personaUUIDString = account.replacingOccurrences(of: "persona.", with: "")
                        .replacingOccurrences(of: "_ethInfo", with: "")
                    if let personaUUID = UUID(uuidString: personaUUIDString) {
                        let storage = LibAuk.shared.storage(for: personaUUID)
                        let sink = storage.exportSeed()
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .failure(let error):
                                // Handle error
                                print("Error exporting seed: \(error)")
                            case .finished:
                                break
                            }
                        }, receiveValue: { seed in
                            
                            do {
                                let seedPublicData = try storage.generateSeedPublicData(seed: seed)
                                let isDevicePasscode = UserDefaults.standard.bool(forKey: "flutter.device_passcode")
                                
                                let setSeedSink = storage.setSeed(seed: seed, isPrivate: isDevicePasscode)
                                    .sink(receiveCompletion: { completion in
                                        // Handle completion
                                    }, receiveValue: { _ in
                                        // Handle value if needed
                                    })
                                
                                setSeedSink.store(in: &self.cancelBag)
                            } catch {
                                // Handle error thrown by generateSeedPublicData
                                print("Error generating seed public data: \(error)")
                            }
                        })
                                    
                        sink.store(in: &self.cancelBag)
                        
                    }
                }
            }
        }
        result([
            "error": 0,
            "data": true
        ])
    }

}

extension Data {
    var personalSignedMessageData: Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(self.count)).data(using: .ascii)!
        return prefixData + self
    }
}

extension Subscribers.Completion {
    var error: Failure? {
        switch self {
        case let .failure(error): return error
        default: return nil
        }
    }
}
