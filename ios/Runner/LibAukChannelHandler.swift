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
                    "msg": "isWalletCreated success",
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
            "msg": "getName success",
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
                    "msg": "exportMnemonicWords success",
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
                    "msg": "exportMnemonicWords success",
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
            "msg": "getETHAddress success",
            "data": address
        ])
    }
    
    func signPersonalMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message = args["message"] as! FlutterStandardTypedData

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .sign(message: [UInt8](message.data.personalSignedMessageData))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "msg": "exportMnemonicWords success",
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
            gas: EthereumQuantity(quantity: BigUInt(Double(gasLimit) ?? 0)),
            from: nil,
            to: try! EthereumAddress.init(hex: to, eip55: false),
            value: EthereumQuantity(quantity: BigUInt(Double(value) ?? 0)),
            data: try! EthereumData.string(data))
        

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .signTransaction(transaction: transaction, chainId: EthereumQuantity(quantity: BigUInt(chainId)))
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { signedTx in
                let bytes: [UInt8] = try! RLPEncoder().encode(signedTx.rlp())
                result([
                    "error": 0,
                    "msg": "exportMnemonicWords success",
                    "data": Data(bytes),
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
                    "msg": "exportMnemonicWords success",
                    "data": words.joined(separator: " "),
                ])
            })
            .store(in: &cancelBag)
    }
    
    func getTezosWallet(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getTezosWallet()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { wallet in
                let hdWallet = wallet as! HDWallet
                result([
                    "error": 0,
                    "msg": "getTezosWallet success",
                    "address": wallet.address,
                    "secretKey": hdWallet.privateKey.data,
                    "publicKey": hdWallet.publicKey.data,
                ])
            })
            .store(in: &cancelBag)
    }
    
    func getBitmarkAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getBitmarkAddress()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }
            }, receiveValue: { address in
                result([
                    "error": 0,
                    "msg": "getBitmarkAddress success",
                    "data": address,
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

    func setupSSKR(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).setupSSKR()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "generateSSKR success",
                ])
            })
            .store(in: &cancelBag)
    }

    func getShard(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let shardType: Int = args["shardType"] as! Int

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .getShard(type: ShardType(rawValue: shardType)!)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (shard) in
                result([
                    "error": 0,
                    "msg": "getShard success",
                    "data": shard,
                ])
            })
            .store(in: &cancelBag)
    }

    func removeShard(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let shardType: Int = args["shardType"] as! Int

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .removeShard(type: ShardType(rawValue: shardType)!)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "removeShard success",
                ])
            })
            .store(in: &cancelBag)
    }

    func restoreByBytewordShards(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let shares: [String] = args["shares"] as! [String]
        let name: String = (args["name"] as? String) ?? ""

        let dateInMili: Double? = args["date"] as? Double
        let date = dateInMili != nil ? Date(timeIntervalSince1970: dateInMili!) : nil

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .restoreByBytewordShards(shares: shares, name: name, creationDate: date)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "restoreByBytewordShards success",
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
