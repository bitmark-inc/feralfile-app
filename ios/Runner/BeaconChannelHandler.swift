//
//  BeaconChannelHandler.swift
//  Runner
//
//  Created by Ho Hien on 08/02/2022.
//

import Combine
import BeaconBlockchainTezos
import BeaconClientWallet
import BeaconTransportP2PMatrix
import BeaconCore
import Base58Swift

class BeaconChannelHandler: NSObject, FlutterStreamHandler {
    
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
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        BeaconConnectService.shared.observeRequest()
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] request in
                self?.requests.append(request)
                var params = [
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
                    case .broadcast(_):
                        params["type"] = "broadcast"
                        break;
                    }
                }
                events([
                    "eventName": "observeRequest",
                    "params": params,
                ])
            })
            .store(in: &cancelBag)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        cancelBag.removeAll()
        return nil
    }
}
