//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import Foundation
import Combine
import BeaconBlockchainTezos
import BeaconClientWallet
import BeaconTransportP2PMatrix
import BeaconCore
import Base58Swift

typealias TezosBeaconRequest = BeaconRequest<Tezos>
typealias TezosBeaconResponse = BeaconResponse<Tezos>
typealias Completion<T> = (Result<T, Error>) -> Void

class BeaconConnectService {
    
    static var shared = BeaconConnectService()
    var beaconClient: Beacon.WalletClient?
    fileprivate let requestSubject = PassthroughSubject<TezosBeaconRequest, Never>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    
    func startBeacon(retryOnFailure: Bool = true) {
        guard beaconClient == nil else {
            listenForRequests()
            return
        }

        do {
            Beacon.WalletClient.create(
                with: .init(
                    name: Constant.appname,
                    blockchains: [Tezos.factory],
                    connections: [try Transport.P2P.Matrix.connection()]
                )
            ) { result in
                switch result {
                case let .success(client):
                    logger.info("[TezosBeaconService]  Beacon client created")
                    self.beaconClient = client
                    self.listenForRequests()

                case let .failure(error):
                    if retryOnFailure && error.localizedDescription.contains("osStatus") {
                        // cleanup keychain
                        let passwordQuery: [AnyHashable:Any] = [
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrAccount as String: "sdkSeed"
                        ]
                        SecItemDelete(passwordQuery as CFDictionary)
                        
                        self.startBeacon(retryOnFailure: false)
                    } else {
                        logger.info("[TezosBeaconService] Could not create Beacon client")
                    }
                }
            }
        } catch {
            logger.info("[TezosBeaconService] Could not create Beacon client")
            logger.info("Error: \(error)")
        }
    }
    
    func listenForRequests() {
        beaconClient?.connect { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                logger.info("[TezosBeaconService] Beacon client connected")
                self.beaconClient?.listen(onRequest: self.onBeaconRequest)

            case let .failure(error):
                logger.info("[TezosBeaconService] Error while connecting for messages")
                logger.error("Error: \(error)")
            }
        }
    }
    
    func onBeaconRequest(_ requestResult: Result<BeaconRequest<Tezos>, Beacon.Error>) {
        switch requestResult {
        case let .success(message):
            requestSubject.send(message)

        case let .failure(error):
            logger.info("Error while processing incoming messages")
            logger.error("Error: \(error)")
        }
    }
    
    func observeRequest() -> AnyPublisher<TezosBeaconRequest, Never> {
        requestSubject.eraseToAnyPublisher()
    }
    
    func addPeer(deeplink: String) -> AnyPublisher<Beacon.P2PPeer, Error> {
        return Just(())
            .flatMap { _ -> AnyPublisher<Beacon.P2PPeer, Error> in
                Future<Beacon.P2PPeer, Error> { [self] (promise) in
                    do {
                        let (pairingRequest, peer) = try self.extractPeer(from: deeplink)

                        guard let beaconClient = self.beaconClient else {
                            throw BeaconConnectError.pendingBeaconClient
                        }

                        beaconClient.add([.p2p(peer)]) { result in
                            switch result {
                            case .success(_):
                                logger.info("[TezosBeaconService] addPeer \(peer) ")
                                beaconClient.pair(with: pairingRequest) { pairResult in
                                    switch pairResult {
                                    case .success(_):
                                        logger.info("[TezosBeaconService] Peer added")
                                        promise(.success(peer))

                                    case let .failure(error):
                                        logger.error("[TezosBeaconService] addPeer Error: \(error)")
                                        promise(.failure(error))
                                    }
                                }
                                logger.info("[TezosBeaconService] Peer added")
                                promise(.success(peer))

                            case let .failure(error):
                                logger.error("[TezosBeaconService] addPeer Error: \(error)")
                                promise(.failure(error))
                            }
                        }
                    } catch {
                        logger.error("Error: \(error)")
                        promise(.failure(error))
                    }
                }
                .eraseToAnyPublisher()

            }
            .eraseToAnyPublisher()
    }

    func removePeer(_ peer: Beacon.P2PPeer) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [self] (promise) in
            self.beaconClient?.removePeers([.p2p(peer)]) { result in
                switch result {
                case .success(_):
                    logger.info("[TezosBeaconService] Peer removed")
                    promise(.success(()))

                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func cleanupSession(_ retainIds: [String]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [self] (promise) in
            self.beaconClient?.getPeers { result in
                switch result {
                case .success(let peers):
                    let retainPeers = peers.filter { peer in !retainIds.contains(peer.id ?? "") }
                    self.beaconClient?.removePeers(retainPeers) { removeResult in
                        switch removeResult {
                        case .success(_):
                            logger.info("[TezosBeaconService] cleanupSession retainIds: \(retainIds)")
                            promise(.success(()))

                        case let .failure(error):
                            promise(.failure(error))
                        }
                    }

                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func response(_ content: TezosBeaconResponse, completion: @escaping Completion<Void>) {
        beaconClient?.respond(with: content, completion: { result in
            switch result {
            case .success(_):
                logger.info("[TezosBeaconService] response successfully")
                completion(.success(()))

            case let .failure(error):
                logger.info("[TezosBeaconService] response error")
                logger.error("Error: \(error)")
                completion(.failure(error))
            }
        })
    }

    func pause() {
        beaconClient?.pause {
            logger.info("[TezosBeaconService] Paused \($0)")
        }
    }

    func resume() {
        beaconClient?.resume {
            logger.info("[TezosBeaconService]] Resumed \($0)")
        }
    }
}

fileprivate extension BeaconConnectService {
    func extractPeer(from deeplink: String) throws -> (String, Beacon.P2PPeer) {
        guard let message = URLComponents(string: deeplink)?.queryItems?.first(where: { $0.name == "data" })?.value,
              let messageData = Base58.base58CheckDecode(message) else {
            logger.info("[invalidDeeplink] \(deeplink)")
            throw AppError.invalidDeeplink
        }

        let decoder = JSONDecoder()
        let data = Data(messageData)
        guard let peer = try? decoder.decode(Beacon.P2PPeer.self, from: data) else {
            logger.info("[invalidDeeplink] \(deeplink)")
            throw AppError.invalidDeeplink
        }

        return (message, peer)
    }
}

enum BeaconConnectError: Error {
    case pendingBeaconClient
}
