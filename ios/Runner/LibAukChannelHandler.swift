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

    func createKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let name: String = (args["name"] as? String) ?? ""
        
        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).createKey(name: name)
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
        let name: String = (args["name"] as? String) ?? ""
        let words: String = (args["words"] as? String) ?? ""
        let dateInMili: Double? = args["date"] as? Double
        
        let date = dateInMili != nil ? Date(timeIntervalSince1970: dateInMili!) : nil
        let wordsArray = words.components(separatedBy: " ")
        
        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .importKey(words: wordsArray, name: name, creationDate:date)
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
    
    func updateName(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let name: String = (args["name"] as? String) ?? ""

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).updateName(name: name)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "updateName success",
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
        let nonce: String = args["nonce"] as? String ?? ""
        let gasPrice: String = args["gasPrice"] as? String ?? ""
        let gasLimit: String = args["gasLimit"] as? String ?? ""
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? ""
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0
        
        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(Double(nonce) ?? 0)),
            gasPrice: EthereumQuantity(quantity: BigUInt(Double(gasPrice) ?? 0)),
            gasLimit: EthereumQuantity(quantity: BigUInt(Double(gasLimit) ?? 0)),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(Double(value) ?? 0)),
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
    
    func signTransaction1559(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let nonce: String = args["nonce"] as? String ?? ""
        let gasLimit: String = args["gasLimit"] as? String ?? ""
        let maxPriorityFeePerGas: String = args["maxPriorityFeePerGas"] as? String ?? ""
        let maxFeePerGas: String = args["maxFeePerGas"] as? String ?? ""
        let to: String = args["to"] as? String ?? ""
        let value: String = args["value"] as? String ?? ""
        let data: String = args["data"] as? String ?? ""
        let chainId: Int = args["chainId"] as? Int ?? 0
        
        let transaction = EthereumTransaction(
            nonce: EthereumQuantity(quantity: BigUInt(Double(nonce) ?? 0)),
            maxFeePerGas: EthereumQuantity(quantity: BigUInt(Double(maxFeePerGas) ?? 0)),
            maxPriorityFeePerGas: EthereumQuantity(quantity: BigUInt(Double(maxPriorityFeePerGas) ?? 0)),
            gasLimit: EthereumQuantity(quantity: BigUInt(Double(gasLimit) ?? 0)),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(Double(value) ?? 0)),
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
    
    func getTezosPublicKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getTezosPublicKey()
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
                    "data": output as! String,
                ])
            })
            .store(in: &cancelBag)
    }

    func decryptFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let inputPath: String = args["inputPath"] as! String
        let outputPath: String = args["outputPath"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .decryptFile(inputPath: inputPath, outputPath: outputPath)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { output in
                result([
                    "error": 0,
                    "data": output as! String,
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
