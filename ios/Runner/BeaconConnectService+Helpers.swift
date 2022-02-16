//
//  BeaconConnectService+Helpers.swift
//  Runner
//
//  Created by Ho Hien on 10/02/2022.
//

import Foundation
import BeaconCore
import BeaconBlockchainTezos

extension PermissionTezosRequest {
    func connect(publicKey: String) -> TezosBeaconResponse {
        .permission(
            PermissionTezosResponse(from: self, publicKey: publicKey)
        )
    }

    func decline() -> TezosBeaconResponse {
        .error(ErrorBeaconResponse(from: self, errorType: .aborted))
    }
}

extension SignPayloadTezosRequest {
    func accept(signature: String) -> TezosBeaconResponse {
        .blockchain(
            .signPayload(SignPayloadTezosResponse(from: self, signature: signature))
        )
    }

    func decline() -> TezosBeaconResponse {
        .error(ErrorBeaconResponse(from: self, errorType: .aborted))
    }
}

extension OperationTezosRequest {
    func done(txHash: String) -> TezosBeaconResponse {
        .blockchain(
            .operation(OperationTezosResponse(from: self, transactionHash: txHash))
        )
    }

    func decline() -> TezosBeaconResponse {
        .error(ErrorBeaconResponse(from: self, errorType: .aborted))
    }
}

enum WalletConnectionEvent {
    case wcRequestedPermission(String)
    case beaconConnecting(String)
    case beaconRequestedPermission(Beacon.P2PPeer)
    case beaconLinked(Beacon.P2PPeer, String, PermissionTezosResponse)
//    case linked(Connection)
    case beaconError(Beacon.Error)
    case error(Error)
    case userAborted
}

enum DappConnectionEvent {
    case tezosWalletClientReady
    case tezosAddingPeer
    case tezosWaitForDappRequest
    case tezosGotDappRequest
    case tezosDone
    case tezosError(error: Error)
    case errorProcessingMessage(error: Error)
    case weirdStuckInAddDapp
}

extension Crypto {
    public func address(fromPublicKey publicKey: String) throws -> String {
        try Tezos.Wallet(crypto: self)
            .address(fromPublicKey: publicKey)
    }
}

extension Beacon.Peer {
    func toP2P() -> Beacon.P2PPeer {
        switch self {
        case let .p2p(peer):
            return peer
        }
    }

}
