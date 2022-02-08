import UIKit
import Flutter
import LibAuk
import BigInt
import Web3
import KukaiCoreSwift
import Combine

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var cancelBag = Set<AnyCancellable>()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LibAuk.create(keyChainGroup: "Z5CE7A3A7N.com.bitmark.autonomywallet.keychain")
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let libaukChannel = FlutterMethodChannel(name: "libauk_dart",
                                                 binaryMessenger: controller.binaryMessenger)
        libaukChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "createKey":
                self.createKey(call: call, result: result)
            case "importKey":
                self.importKey(call: call, result: result)
            case "getName":
                self.getName(call: call, result: result)
            case "updateName":
                self.updateName(call: call, result: result)
            case "isWalletCreated":
                self.isWalletCreated(call: call, result: result)
            case "getETHAddress":
                self.getETHAddress(call: call, result: result)
            case "signPersonalMessage":
                self.signPersonalMessage(call: call, result: result)
            case "exportMnemonicWords":
                self.exportMnemonicWords(call: call, result: result)
            case "signTransaction":
                self.signTransaction(call: call, result: result)
            case "getTezosWallet":
                self.getTezosWallet(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        let migrationChannel = FlutterMethodChannel(name: "migration_util",
                                                    binaryMessenger: controller.binaryMessenger)
        migrationChannel.setMethodCallHandler({(call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "getExistingUuids") {
                result("")
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func createKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let name: String = (args["name"] as? String) ?? ""
        
        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).createKey(name: name)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "createKey success",
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func importKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let name: String = (args["name"] as? String) ?? ""
        let words: String = (args["words"] as? String) ?? ""
        let dateInMili: Double? = args["date"] as? Double
        
        let date = dateInMili != nil ? Date(timeIntervalSince1970: dateInMili!) : nil
        let wordsArray = words.components(separatedBy: " ")
        
        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).importKey(words: wordsArray, name: name, creationDate:date)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "importKey success",
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func updateName(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let name: String = (args["name"] as? String) ?? ""

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).updateName(name: name)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "updateName success",
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func isWalletCreated(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        
        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).isWalletCreated()
            .sink(receiveCompletion: { _ in }, receiveValue: { isCreated in
                result([
                    "error": 0,
                    "msg": "isWalletCreated success",
                    "data": isCreated,
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func getName(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        
        let address = LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getName() ?? ""
        
        result([
            "error": 0,
            "msg": "getName success",
            "data": address
        ])
    }
    
    private func getETHAddress(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        
        let address = LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getETHAddress() ?? ""
        
        result([
            "error": 0,
            "msg": "getETHAddress success",
            "data": address
        ])
    }
    
    private func signPersonalMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String
        let message: Data = args["message"] as! Data

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!)
            .sign(message: [UInt8](message.personalSignedMessageData))
            .sink(receiveCompletion: { _ in }, receiveValue: { (v, r, s) in
                result([
                    "error": 0,
                    "msg": "exportMnemonicWords success",
                    "data": "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16),
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func signTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
            .sink(receiveCompletion: { _ in }, receiveValue: { signedTx in
                let bytes: [UInt8] = try! RLPEncoder().encode(signedTx.rlp())
                result([
                    "error": 0,
                    "msg": "exportMnemonicWords success",
                    "data": Data(bytes),
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func exportMnemonicWords(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).exportMnemonicWords()
            .sink(receiveCompletion: { _ in }, receiveValue: { words in
                result([
                    "error": 0,
                    "msg": "exportMnemonicWords success",
                    "data": words.joined(separator: " "),
                ])
            })
            .store(in: &cancelBag)
    }
    
    private func getTezosWallet(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let uuid: String = args["uuid"] as! String

        LibAuk.shared.storage(for: UUID(uuidString: uuid)!).getTezosWallet()
            .sink(receiveCompletion: { _ in }, receiveValue: { wallet in
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
    
}

extension Data {
    var personalSignedMessageData: Data {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(self.count)).data(using: .ascii)!
        return prefixData + self
    }
}
