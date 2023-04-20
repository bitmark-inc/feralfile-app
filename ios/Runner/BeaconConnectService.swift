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
import BeaconBlockchainSubstrate

typealias TezosBeaconRequest = BeaconRequest<Tezos>
typealias TezosBeaconResponse = BeaconResponse<Tezos>
typealias Completion<T> = (Result<T, Error>) -> Void

class BeaconConnectService {
    
    static var shared = BeaconConnectService()
    var beaconClient: Beacon.WalletClient?
    fileprivate let requestSubject = PassthroughSubject<TezosBeaconRequest, Never>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    
    let eventsSubject = PassthroughSubject<WalletConnectionEvent, Never>()
    
    func startBeacon(retryOnFailure: Bool = true) {
        guard beaconClient == nil else {
            listenForRequests()
            return
        }

        do {
            Beacon.WalletClient.create(
                with: .init(
                    name: Constant.appname,
                    blockchains: [Tezos.factory, Substrate.factory],
                    connections: [try Transport.P2P.Matrix.connection()],
                    secureStorage: UserDefaultsSecureStorage(userDefaults: .standard, accessGroup: Constant.keychainGroup)
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
//                        logger.error("Error: \(error)")
                    }
                }
            }
        } catch {
            logger.info("[TezosBeaconService] Could not create Beacon client")
            logger.info("Error: \(error)")
        }
    }
    
    func listenForRequests() {
        startOpenChannelListener(completion: { result in
            switch result {
            case let .failure(error):
                logger.info("[TezosBeaconService] Error while startOpenChannelListener")
                logger.error("Error: \(error)")
            default:
                break
            }
        })
        
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
    
    func onBeaconRequest(result: Result<BeaconMessage<Tezos>, Beacon.Error>) {
        switch result {
        case let .success(message):
            switch message {
            case let .request(request):
                requestSubject.send(request)
            case let .response(response):
                switch response {
                case let .permission(permissionResponse):
                    guard let beaconDappClient = beaconClient else { return }
                    let peerPublicKey = permissionResponse.requestOrigin.id

                    beaconDappClient.storageManager.findPeers(where: { $0.publicKey == peerPublicKey }) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case let .success(peer):
                            guard let p2pPeer = peer?.toP2P() else { return }
                            self.eventsSubject
                                .send(.beaconLinked(p2pPeer, permissionResponse.account.address, permissionResponse))

                        case let .failure(error):
                            self.eventsSubject
                                .send(.error(error))
                        }

                    }

                case let .error(errorResponse):
                    switch errorResponse.errorType {
                    case .aborted:
                        self.eventsSubject
                            .send(.userAborted)

                    default:
                        // Ignore for now
                        break
                    }


                default:
                    // Ignore for now
                    break
                }
            default:
                break
            }

        case let .failure(error):
            logger.info("Error while processing incoming messages")
            logger.error("Error: \(error)")
        }
    }
    
    func observeRequest() -> AnyPublisher<TezosBeaconRequest, Never> {
        requestSubject.eraseToAnyPublisher()
    }
    
    func observeEvents() -> AnyPublisher<WalletConnectionEvent, Never> {
        eventsSubject.eraseToAnyPublisher()
    }
    
    func addPeer(deeplink: String) -> AnyPublisher<Beacon.P2PPeer, Error> {
        return Just(())
            .flatMap { _ -> AnyPublisher<Beacon.P2PPeer, Error> in
                Future<Beacon.P2PPeer, Error> { [self] (promise) in
                    do {
                        let peer = try self.extractPeer(from: deeplink)

                        guard let beaconClient = self.beaconClient else {
                            throw BeaconConnectError.pendingBeaconClient
                        }

                        logger.info("[TezosBeaconService] addPear \(peer) ")

                        beaconClient.add([.p2p(peer)]) { result in
                            switch result {
                            case .success(_):
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
            self.beaconClient?.remove([.p2p(peer)]) { result in
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
                    self.beaconClient?.remove(retainPeers) { removeResult in
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

//DApp Beacon
extension BeaconConnectService {
    
    func getConnectionURI() -> AnyPublisher<String, Error> {
        Future<String, Error> { [weak self] (promise) in
            guard let self = self,
                  let beaconDappClient = self.beaconClient else {
                promise(.failure(AppError.pendingBeaconClient))
                return
            }

            beaconDappClient.newOwnSerializedPeer { result in
                switch result {
                case let .success(data):
                    promise(.success("?type=tzip10&data=\(data)"))
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask (withName: data) {
                        // End the task if time expires.
                        UIApplication.shared.endBackgroundTask(self.backgroundTaskID!)
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }

                case let .failure(error):
                    logger.error("Error: \(error)")
                    promise(.failure(error))
                }
            }

        }
        .eraseToAnyPublisher()
    }

    private func startOpenChannelListener(completion: @escaping (Result<(), Beacon.Error>) -> Void) {
        guard let beaconClient = beaconClient else {
            completion(.failure(.uninitialized))
            return
        }

        beaconClient.connectionController.startOpenChannelListener { [weak self] (result: Result<Beacon.Peer, Swift.Error>) in
            logger.info("[startOpenChannelListener][event]")
            guard let newPeer = result.get(ifFailure: completion) else { return }

            beaconClient.getOwnAppMetadata { appMetadataResult in

                let result = appMetadataResult.map { appMetadata in

                    let permissionRequest = PermissionV2TezosRequest(
                        version: "2",
                        id: UUID().uuidString.lowercased(),
                        senderID: appMetadata.senderID,
                        appMetadata:  PermissionV2TezosRequest.AppMetadata(from: appMetadata),
                        network: Tezos.Network(type: .mainnet, name: nil, rpcURL: nil),
                        scopes: [Tezos.Permission.Scope.operationRequest, Tezos.Permission.Scope.sign]
                    )

                    permissionRequest.toBeaconMessage(
                        with: Beacon.Origin.p2p(id: newPeer.publicKey)) { (result) in
                            guard let permissionRequestMessage = result.get(ifFailure: completion) else { return }

                            beaconClient.request(with: permissionRequestMessage) { [weak self] result in
                                guard let self = self else { return }

                                switch result {
                                case .success:
                                    self.eventsSubject.send(.beaconRequestedPermission(newPeer.toP2P()))

                                case let .failure(error):
                                    logger.error("Error: \(error)")
                                    completion(.failure(error))
                                }
                            }
                        }
                }

                completion(result)
            }
        }
    }
}

fileprivate extension BeaconConnectService {
    func extractPeer(from deeplink: String) throws -> Beacon.P2PPeer {
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

        return peer
    }
}

enum BeaconConnectError: Error {
    case pendingBeaconClient
}
