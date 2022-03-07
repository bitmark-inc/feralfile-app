//
//  BeaconConnect.swift
//  Runner
//
//  Created by Ho Hien on 08/02/2022.
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
    private var beaconClient: Beacon.WalletClient?
    fileprivate let requestSubject = PassthroughSubject<TezosBeaconRequest, Never>()
    private var backgroundTaskID: UIBackgroundTaskIdentifier?
    
    var beaconDappClient: Beacon.DAppClient?
    let eventsSubject = PassthroughSubject<WalletConnectionEvent, Never>()
    
    func startBeacon() {
        guard beaconClient == nil else {
            listenForRequests()
            return
        }

        do {
            Beacon.WalletClient.create(
                with: .init(
                    name: Constant.appname,
                    blockchains: [Tezos.factory],
                    connections: [.p2p(.init(client: try Transport.P2P.Matrix.factory()))]
                )
            ) { result in
                switch result {
                case let .success(client):
                    print("[TezosBeaconService]  Beacon client created")
                    self.beaconClient = client
                    self.listenForRequests()

                case let .failure(error):
                    print("[TezosBeaconService] Could not create Beacon client")
                    print("Error: \(error)")
                }
            }
        } catch {
            print("[TezosBeaconService] Could not create Beacon client")
            print("Error: \(error)")
        }
    }
    
    func listenForRequests() {
        beaconClient?.connect { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(_):
                print("[TezosBeaconService] Beacon client connected")
                self.beaconClient?.listen(onRequest: self.onBeaconRequest)

            case let .failure(error):
                print("[TezosBeaconService] Error while connecting for messages")
                print("Error: \(error)")
            }
        }
    }
    
    func onBeaconRequest(result: Result<BeaconRequest<Tezos>, Beacon.Error>) {
        switch result {
        case let .success(request):
            requestSubject.send(request)

        case let .failure(error):
            print("Error while processing incoming messages")
            print("Error: \(error)")
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

                        beaconClient.add([.p2p(peer)]) { result in
                            switch result {
                            case .success(_):
                                print("[TezosBeaconService] Peer added")
                                promise(.success(peer))

                            case let .failure(error):
                                promise(.failure(error))
                            }
                        }
                    } catch {
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
                    print("[TezosBeaconService] Peer removed")
                    promise(.success(()))

                case let .failure(error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removePeerFromDApp(_ peer: Beacon.P2PPeer) -> AnyPublisher<Void, Error> {
        print("[TezosBeaconService] removePeerFromDApp")

        return Future<Void, Error> { [self] (promise) in
            self.beaconDappClient?.remove([.p2p(peer)]) { result in
                switch result {
                case .success:
                    print("[TezosBeaconService][Done] removePeerFromDApp")
                    promise(.success(()))

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
                print("[TezosBeaconService] response successfully")
                completion(.success(()))

            case let .failure(error):
                print("[TezosBeaconService] response error")
                completion(.failure(error))
            }
        })
    }

    func pause() {
        beaconClient?.pause {
            print("[TezosBeaconService] Paused \($0)")
        }
    }

    func resume() {
        beaconClient?.resume {
            print("[TezosBeaconService]] Resumed \($0)")
        }
    }
    
}

//DApp Beacon
extension BeaconConnectService {
    
    func getConnectionURI() -> AnyPublisher<String, Error> {
        Future<String, Error> { [weak self] (promise) in
            guard let self = self,
                  let beaconDappClient = self.beaconDappClient else {
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
                    promise(.failure(error))
                }
            }

        }
        .eraseToAnyPublisher()
    }
    
    func startDAppBeacon() {
        guard beaconDappClient == nil else {
            listenForDappRequests()
            return
        }

        do {
            let storage = UserDefaultsP2PMatrixStoragePlugin(userDefaults: (.init(suiteName: "DappClient") ?? .standard))

            Beacon.DAppClient.create(
                with: .init(
                    name: Constant.appname,
                    blockchains: [Tezos.factory],
                    connections: [.p2p(.init(client: try Transport.P2P.Matrix.factory(storagePlugin: storage)))]
                )
            ) { result in
                switch result {
                case let .success(client):
                    print("[TezosBeaconService][Done] Beacon.DAppClient.create")
                    self.beaconDappClient = client
                    self.listenForDappRequests()

                case let .failure(error):
                    print("[TezosBeaconService][Error] Beacon.DAppClient.create")
                    print("Error: \(error)")
                }
            }
        } catch {
            print("[TezosBeaconService][Error] Beacon.DAppClient.create")
            print("Error: \(error)")
        }
    }

    private func listenForDappRequests() {
        startOpenChannelListener(completion: { result in
            switch result {
            case let .failure(error):
                print("[TezosBeaconService] Error while startOpenChannelListener")
                print("Error: \(error)")

            default:
                break
            }
        })

        beaconDappClient?.connect { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                print("[TezosBeaconService] beaconDappClient connected")
                self.beaconDappClient?.listen(onResponse: self.onBeaconResponse)

            case let .failure(error):
                print("[TezosBeaconService] Error while connecting beaconDappClient")
                print("Error: \(error)")
            }
        }
    }

    private func startOpenChannelListener(completion: @escaping (Result<(), Beacon.Error>) -> Void) {
        guard let beaconClient = beaconDappClient else {
            completion(.failure(.uninitialized))
            return
        }

        beaconClient.connectionController.startOpenChannelListener { [weak self] (result: Result<Beacon.Peer, Swift.Error>) in
            print("[startOpenChannelListener][event]")
            guard let newPeer = result.get(ifFailure: completion) else { return }

            beaconClient.getOwnAppMetadata { appMetadataResult in

                let result = appMetadataResult.map { appMetadata in

                    let permissionRequest = PermissionTezosRequest(
                        type: "permission_request",
                        id: UUID().uuidString.lowercased(),
                        blockchainIdentifier: Tezos.identifier,
                        senderID: appMetadata.senderID,
                        appMetadata: appMetadata,
                        network: Tezos.Network(type: .mainnet, name: nil, rpcURL: nil),
                        scopes: [Tezos.Permission.Scope.operationRequest, Tezos.Permission.Scope.sign],
                        origin: Beacon.Origin.p2p(id: newPeer.publicKey),
                        version: "2")

                    let beaconRequest: BeaconRequest<Tezos> = .permission(permissionRequest)

                    beaconClient.request(with: beaconRequest) { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success:
                            self.eventsSubject.send(.beaconRequestedPermission(newPeer.toP2P()))

                        case let .failure(error):
                            completion(.failure(error))
                        }
                    }
                }

                completion(result)
            }
        }
    }

    private func onBeaconResponse(result: Result<BeaconResponse<Tezos>, Beacon.Error>) {
        switch result {
        case let .success(response):
            switch response {
            case let .permission(permissionResponse):
                guard let beaconDappClient = beaconDappClient else { return }
                let publicKey = permissionResponse.publicKey
                let peerPublicKey = permissionResponse.requestOrigin.id

                beaconDappClient.storageManager.findPeers(where: { $0.publicKey == peerPublicKey }) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case let .success(peer):
                        guard let p2pPeer = peer?.toP2P(), let tzAddress = try? beaconDappClient.crypto.address(fromPublicKey: publicKey) else { return }
                        self.eventsSubject
                            .send(.beaconLinked(p2pPeer, tzAddress, permissionResponse))

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

        case let .failure(error):
            print("Error while processing incoming response")
            print("Error: \(error)")
        }
    }
}

fileprivate extension BeaconConnectService {
    func extractPeer(from deeplink: String) throws -> Beacon.P2PPeer {
        guard let message = URLComponents(string: deeplink)?.queryItems?.first(where: { $0.name == "data" })?.value,
              let messageData = Base58.base58CheckDecode(message) else {
                  throw BeaconConnectError.invalidDeeplink
              }

        let decoder = JSONDecoder()
        let data = Data(messageData)
        guard let peer = try? decoder.decode(Beacon.P2PPeer.self, from: data) else {
            throw BeaconConnectError.invalidDeeplink
        }

        return peer
    }
}

enum BeaconConnectError: Error {
    case invalidDeeplink
    case pendingBeaconClient
}
