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
    
    func startBeacon() {
        guard beaconClient == nil else {
            listenForRequests()
            return
        }

        do {
            Beacon.WalletClient.create(
                with: .init(
                    name: "Autonomy",
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
