//
//  BeaconChannelHandler.swift
//  Runner
//
//  Created by Ho Hien on 08/02/2022.
//

import Combine
import Flutter
import BeaconBlockchainTezos
import BeaconClientWallet
import BeaconTransportP2PMatrix
import BeaconCore
import Base58Swift

class BeaconChannelHandler: NSObject {
    
    static let shared = BeaconChannelHandler()
    private var cancelBag = Set<AnyCancellable>()
    private var requests = [TezosBeaconRequest]()
    
    func connect() {
        BeaconConnectService.shared.startBeacon()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            BeaconConnectService.shared.startDAppBeacon()
        }
    }
    
    func addPeer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args: NSDictionary = call.arguments as! NSDictionary
        let link: String = args["link"] as! String

        BeaconConnectService.shared.addPeer(deeplink: link)
            .sink(receiveCompletion: { _ in }, receiveValue: { peer in
                result([
                    "error": 0,
                    "id": peer.id ?? "",
                    "version": peer.version,
                    "publicKey": peer.publicKey,
                    "icon": peer.icon ?? "",
                    "name": peer.name,
                    "relayServer": peer.relayServer,
                    "appURL": peer.appURL?.absoluteString ?? "",
                ])
            })
            .store(in: &cancelBag)
    }
    
    func removePeer(call: FlutterMethodCall, result: @escaping FlutterResult) {
//        BeaconConnectService.shared.removePeer()
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
                response = permissionRequest.connect(publicKey: publicKey)
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
            .sink(receiveCompletion: { _ in }, receiveValue: { uri in
                result([
                    "error": 0,
                    "uri": uri,
                ])
            })
            .store(in: &cancelBag)
    }
}

extension BeaconChannelHandler: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.observerRequests(events: events)
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancelBag.removeAll()
        return nil
    }
    
    private func observerRequests(events: @escaping FlutterEventSink) {
        BeaconConnectService.shared.observeRequest()
            .sink { [weak self] request in
                self?.requests.append(request)
                var params: [String: Any] = [
                        "id": request.id,
                        "blockchainIdentifier": request.blockchainIdentifier,
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
                        operation.operationDetails.forEach({ operation in
                            switch operation {
                            case let .transaction(transaction):
                                
                                let entrypoint: String

                                switch transaction.parameters?.entrypoint {
                                case let .custom(custom):
                                    entrypoint = custom
                                case let .common(common):
                                    entrypoint = common.rawValue
                                case .none:
                                    entrypoint = ""
                                }
                                
                                func getParams(value: Micheline.MichelsonV1Expression) -> [String: Any] {
                                    var params: [String: Any] = [:]

                                    switch value {
                                    case let .literal(literal):
                                        switch literal {
                                        case .string(let string):
                                            params["string"] = string
                                        case .int(let value):
                                            params["int"] = value
                                        case .bytes(let array):
                                            params["bytes"] = array
                                        }
                                    case let .prim(prim):
                                        params["prim"] = prim.prim
                                        params["args"] = prim.args?.map({ getParams(value: $0) })
                                    case .sequence(_):
                                        break
                                    }
                                    
                                    return params
                                }
                                
                                let params: [String: Any]
                                if let value = transaction.parameters?.value {
                                    params = getParams(value: value)
                                } else {
                                    params = [:]
                                }

                                
                                let detail: [String : Any?] = [
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
                    params["type"] = "beaconRequestedPermissionp"
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
