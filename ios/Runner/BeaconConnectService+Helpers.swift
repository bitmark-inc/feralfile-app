//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Combine
import Foundation
import BeaconCore
import BeaconBlockchainTezos

extension PermissionTezosRequest {
    func connect(publicKey: String, address: String) throws -> TezosBeaconResponse {
        return .permission(
            PermissionTezosResponse(
                from: self,
                account: try Tezos.Account(
                    publicKey: publicKey,
                    address: address,
                    network: network
                ))
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
        .error(ErrorBeaconResponse(id: id, version: version, requestOrigin: origin, errorType: .aborted))
    }
}

extension OperationTezosRequest {
    func done(txHash: String) -> TezosBeaconResponse {
        .blockchain(
            .operation(OperationTezosResponse(from: self, transactionHash: txHash))
        )
    }

    func decline() -> TezosBeaconResponse {
        .error(ErrorBeaconResponse(id: id, version: version, requestOrigin: origin, errorType: .aborted))
    }
}

enum WalletConnectionEvent {
    case beaconRequestedPermission(Beacon.P2PPeer)
    case beaconLinked(Beacon.P2PPeer, String, PermissionTezosResponse)
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

extension Beacon.WalletClient {

    func newOwnSerializedPeer(completion: @escaping (Result<String, Beacon.Error>) -> Void) {
        guard let beacon = Beacon.shared else {
            completion(.failure(.uninitialized))
            return
        }

        getRelayServers { result in
            switch result {
            case let .success(relayServers):
                let peer = Beacon.P2PPeer(
                    id: UUID().uuidString.lowercased(),
                    name: self.name,
                    publicKey: HexString(from: beacon.app.keyPair.publicKey).asString(),
                    relayServer: relayServers.first ?? "beacon-node-1.sky.papers.tech",
                    version: "2",
                    icon: nil,
                    appURL: nil)

                do {
                    let serializedPeer = try beacon.dependencyRegistry.serializer.serialize(message: peer)
                    completion(.success(serializedPeer))

                } catch {
                    completion(.failure(Beacon.Error(error)))
                }

            case let .failure(error):
                completion(.failure(error))

            }
        }
    }
}
