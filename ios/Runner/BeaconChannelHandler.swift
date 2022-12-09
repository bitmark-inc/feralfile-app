//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Combine
import Flutter
import BeaconBlockchainTezos
import BeaconClientWallet
import BeaconTransportP2PMatrix
import BeaconCore
import Base58Swift
import SwiftUI

class BeaconChannelHandler: NSObject {
    
    static let shared = BeaconChannelHandler()
    private var cancelBag = Set<AnyCancellable>()
    private var requests = [TezosBeaconRequest]()
    
    func connect() {
        BeaconConnectService.shared.startBeacon()
    }
    
    func addPeer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let link: String = args["link"] as! String

        BeaconConnectService.shared.addPeer(deeplink: link)
            .tryMap { try JSONEncoder().encode($0) }
            .map { String(data: $0, encoding: .utf8) }
            .sink(receiveCompletion: {  (completion) in
                if let error = completion.error {
                    result(ErrorHandler.flutterError(error: error, "Failed to addPeer"))
                }

            }, receiveValue: { serializedPeer in
                result([
                    "error": 0,
                    "result": serializedPeer as Any
                ])
            })
            .store(in: &cancelBag)
    }
    
    func removePeer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let args: NSDictionary = call.arguments as! NSDictionary
            let peerJSON: String = args["peer"] as! String

            let decoder = JSONDecoder()
            let peer = try decoder.decode(Beacon.P2PPeer.self, from: Data(peerJSON))

            BeaconConnectService.shared.removePeer(peer)
                .sink(receiveCompletion: { (completion) in
                    if let error = completion.error {
                        result(
                            FlutterError(code: "Failed to removePeer", message: error.localizedDescription, details: nil)
                        )
                    }

                }, receiveValue: { _ in
                    result([
                        "error": 0,
                        "msg": "removePeer success",
                    ])
                })
                .store(in: &cancelBag)

        } catch {
            result(
                FlutterError(code: "Failed to removePeer", message: error.localizedDescription, details: nil)
            )
        }

    }
    
    func cleanupSessions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let retainIds: [String] = args["retain_ids"] as! [String]

        BeaconConnectService.shared.cleanupSession(retainIds)
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(
                        FlutterError(code: "Failed to cleanupSession", message: error.localizedDescription, details: nil)
                    )
                }

            }, receiveValue: { _ in
                result([
                    "error": 0,
                    "msg": "cleanupSession success",
                ])
            })
            .store(in: &cancelBag)

    }
    
    func response(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id: String = args["id"] as! String
        
        let request = requests.first(where: { $0.id == id })
        var response: TezosBeaconResponse?
        
        switch request {
        case let .permission(permissionRequest):
            let publicKey: String? = args["publicKey"] as? String

            if let publicKey = publicKey {
                guard let address = args["address"] as? String else { return }
                response = try! permissionRequest.connect(publicKey: publicKey, address: address)
            } else {
                response = permissionRequest.decline()
            }
        case let .blockchain(blockchainRequest):
            switch blockchainRequest {
            case let .signPayload(signPayload):
                let signature: String? = args["signature"] as? String
                if let signature = signature {
                    response = signPayload.accept(signature: signature)
                } else {
                    response = signPayload.decline()
                }
            case let .operation(operation):
                let txHash: String? = args["txHash"] as? String
                if let txHash = txHash {
                    response = operation.done(txHash: txHash)
                } else {
                    response = operation.decline()
                }
            default:
                break
            }
        default:
            break
        }
        
        guard let response = response else { return }
        
        BeaconConnectService.shared.response(response, completion: { _ in
            result([
                "error": 0,
            ])
        })
    }
    
    func pause(call: FlutterMethodCall, result: @escaping FlutterResult) {
        BeaconConnectService.shared.pause()
    }
    
    func resume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        BeaconConnectService.shared.resume()
    }
    
    func getConnectionURI(call: FlutterMethodCall, result: @escaping FlutterResult) {
        BeaconConnectService.shared.getConnectionURI()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { uri in
                result([
                    "error": 0,
                    "uri": uri,
                ])
            })
            .store(in: &cancelBag)
    }

    func getPostMessageConnectionURI(call: FlutterMethodCall, result: @escaping FlutterResult) {
        BeaconConnectService.shared.getPostMessageConnectionURI()
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (uri) in
                result([
                    "error": 0,
                    "uri": uri,
                ])
            })
            .store(in: &cancelBag)
    }

    func handlePostMessageOpenChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let payload: String = args["payload"] as! String

        BeaconConnectService.shared.handlePostMessageOpenChannel(payload: payload)
            .tryMap { (peer, permissionRequestMessage) -> (String, String) in
                guard let serializedPeer = String(data: try JSONEncoder().encode(peer), encoding: .utf8) else {
                    throw AppError.incorrectData
                }

                return (serializedPeer, permissionRequestMessage)
            }
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (response) in
                result([
                    "error": 0,
                    "peer": response.0,
                    "permissionRequestMessage": response.1,
                ])
            })
            .store(in: &cancelBag)
    }

    func handlePostMessageMessage(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let extensionPublicKey: String = args["extensionPublicKey"] as! String
        let payload: String = args["payload"] as! String

        BeaconConnectService.shared.handlePostMessageMessage(
            extensionPublicKey: extensionPublicKey,
            payload: payload)
            .tryMap { (tzAddress, tezosResponse) -> (String, String) in
                guard let serializedTezosResponse = String(data: try JSONEncoder().encode(tezosResponse), encoding: .utf8) else {
                    throw AppError.incorrectData
                }

                return (tzAddress, serializedTezosResponse)
            }
            .sink(receiveCompletion: { (completion) in
                if let error = completion.error {
                    result(ErrorHandler.handle(error: error))
                }

            }, receiveValue: { (response) in
                result([
                    "error": 0,
                    "tzAddress": response.0,
                    "response": response.1,
                ])
            })
            .store(in: &cancelBag)
    }

}

extension BeaconChannelHandler: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.observerRequests(events: events)
        self.observeEvents(events: events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancelBag.removeAll()
        return nil
    }
    
    private func observerRequests(events: @escaping FlutterEventSink) {
        BeaconConnectService.shared.observeRequest()
            .throttle(for: 1.0, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] request in
                self?.requests.append(request)
                var params: [String: Any] = [
                        "id": request.id,
                        "senderID": request.senderID,
                        "version": request.version,
                        "originID": request.origin.id,
                    ]
                
                switch request {
                case let .permission(permissionRequest):
                    params["type"] = "permission"
                    params["icon"] = permissionRequest.appMetadata.icon
                    params["appName"] = permissionRequest.appMetadata.name

                    
                case let .blockchain(blockchainRequest):
                    switch blockchainRequest {
                    case let .signPayload(signPayload):
                        params["type"] = "signPayload"
                        params["icon"] = signPayload.appMetadata?.icon ?? ""
                        params["appName"] = signPayload.appMetadata?.name ?? ""
                        params["payload"] = signPayload.payload
                        params["sourceAddress"] = signPayload.sourceAddress
                    case let .operation(operation):
                        params["type"] = "operation"
                        params["icon"] = operation.appMetadata?.icon ?? ""
                        params["appName"] = operation.appMetadata?.name ?? ""
                        params["sourceAddress"] = operation.sourceAddress
                        
                        var operationDetails = [[String:Any?]]()
                        
                        func getParams(value: Micheline.MichelsonV1Expression) -> Any {
                            var params: [String: Any] = [:]

                            switch value {
                            case let .literal(literal):
                                switch literal {
                                case .string(let string):
                                    params["string"] = string
                                case .int(let value):
                                    params["int"] = value
                                case .bytes(let array):
                                    params["bytes"] = HexString(from: array).asString(withPrefix: false)
                                }
                            case let .prim(prim):
                                params["prim"] = prim.prim
                                params["args"] = prim.args?.map({ getParams(value: $0) })
                                if let annots = prim.annots {
                                    params["annots"] = annots
                                }
                                
                            case .sequence(let array):
                                var result = [Any]()
                                for mv1e in array {
                                    result.append(getParams(value: mv1e))
                                }

                                return result
                            }
                            
                            return params
                        }
                        
                        operation.operationDetails.forEach({ operation in
                            switch operation {
                            case let .transaction(transaction):
                                
                                let entrypoint: String?

                                switch transaction.parameters?.entrypoint {
                                case let .custom(custom):
                                    entrypoint = custom
                                case let .common(common):
                                    entrypoint = common.rawValue
                                case .none:
                                    entrypoint = nil
                                }
                                
                                let params: Any?
                                if let value = transaction.parameters?.value {
                                    params = getParams(value: value)
                                } else {
                                    params = nil
                                }
                                
                                let detail: [String : Any?] = [
                                    "kind": "transaction",
                                    "source": transaction.source,
                                    "gasLimit": transaction.gasLimit,
                                    "storageLimit": transaction.storageLimit,
                                    "fee": transaction.fee,
                                    "amount": transaction.amount,
                                    "counter": transaction.counter,
                                    "destination": transaction.destination,
                                    "entrypoint": entrypoint,
                                    "parameters": params,
                                ]
                                operationDetails.append(detail)
                            case let .origination(origination):
                                let code = getParams(value: origination.script.code)
                                let storage = getParams(value: origination.script.storage)
                                
                                let detail: [String : Any?] = [
                                    "kind": "origination",
                                    "source": origination.source,
                                    "gasLimit": origination.gasLimit,
                                    "storageLimit": origination.storageLimit,
                                    "fee": origination.fee,
                                    "balance": origination.balance,
                                    "counter": origination.counter,
                                    "code": code,
                                    "storage": storage,
                                ]
                                operationDetails.append(detail)
                            default:
                                break
                            }
                        })

                        
                        params["operationDetails"] = operationDetails
                    case .broadcast(_):
                        params["type"] = "broadcast"
                        break;
                    }
                }
                events([
                    "eventName": "observeRequest",
                    "params": params,
                ])
            }
            .store(in: &cancelBag)
    }
    
    func observeEvents(events: @escaping FlutterEventSink) {
        BeaconConnectService.shared.observeEvents()
            .sink { (event) in
                var params: [String: Any] = [:]
                
                switch event {
                case let .beaconRequestedPermission(peer):
                    params["type"] = "beaconRequestedPermission"
                    let data = try? JSONEncoder().encode(peer)
                    params["peer"] = data
                case let .beaconLinked(p2pPeer, address, permissionResponse):
                    let dappConnection = TezosWalletConnection(address: address, peer: p2pPeer, permissionResponse: permissionResponse)
                    let data = try? JSONEncoder().encode(dappConnection)
                    params["type"] = "beaconLinked"
                    params["connection"] = data
                case .error(_):
                    params["type"] = "error"
                case .userAborted:
                    params["type"] = "userAborted"
                }
                
                events([
                    "eventName": "observeEvent",
                    "params": params,
                ])
            }
            .store(in: &cancelBag)
    }
}

struct TezosWalletConnection: Codable {
    let address: String
    let peer: Beacon.P2PPeer
    let permissionResponse: PermissionTezosResponse
}
