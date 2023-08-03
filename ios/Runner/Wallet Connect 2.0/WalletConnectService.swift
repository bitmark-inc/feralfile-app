//
//  WalletConnectService.swift
//  Runner
//
//  Created by Ho Hien on 23/08/2022.
//

import WalletConnectPairing
import WalletConnectSign
import WalletConnectUtils
import JSONRPC

class WalletConnectService {
    
    static var shared = WalletConnectService()
    
    @MainActor
    func respondOnApprove(request: Request, response: AnyCodable) {
        logger.info("[WALLET] Respond on Sign")
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id ,response: .response(response))
            } catch {
                logger.info("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func respondOnReject(request: Request, reason: String) {
        logger.info("[WALLET] Respond on Reject")
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(JSONRPCError(code: 0, message: reason, data: nil))
                )
            } catch {
                logger.info("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func pairClient(uri: String) {
        logger.info("[WALLET] Pairing to: \(uri)")
        Task {
            do {
                try await Sign.instance.pair(uri: WalletConnectURI(string: uri)!)
            } catch {
                logger.info("[DAPP] Pairing connect error: \(error)")
            }
        }
    }
    
    @MainActor
    func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        logger.info("[WALLET] Approve Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
            } catch {
                logger.info("[DAPP] Approve Session error: \(error)")
            }
        }
    }
    
    @MainActor
    func reject(proposalId: String, reason: RejectionReason) {
        logger.info("[WALLET] Reject Session: \(proposalId)")
        Task {
            do {
                try await Sign.instance.reject(proposalId: proposalId, reason: reason)
            } catch {
                logger.info("[DAPP] Reject Session error: \(error)")
            }
        }
    }

    @MainActor
    func getPairings() -> [Pairing] {
        logger.info("[WALLET] getPairings")
        return Pair.instance.getPairings()
    }

    @MainActor
    func deletePairing(topic: String) throws {
        Task {
            try await Pair.instance.disconnect(topic: topic)
        }
    }
}
