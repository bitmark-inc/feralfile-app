//
//  WalletConnectService.swift
//  Runner
//
//  Created by Ho Hien on 23/08/2022.
//

import WalletConnectSign
import WalletConnectUtils

class WalletConnectService {
    
    static var shared = WalletConnectService()
    
    @MainActor
    func respondOnApprove(request: Request, response: JSONRPCResponse<AnyCodable>) {
        logger.info("[WALLET] Respond on Sign")
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, response: .response(response))
            } catch {
                logger.info("[DAPP] Respond Error: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func respondOnReject(request: Request) {
        logger.info("[WALLET] Respond on Reject")
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    response: .error(JSONRPCErrorResponse(
                        id: request.id,
                        error: JSONRPCErrorResponse.Error(code: 0, message: ""))
                                    )
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
                try await Sign.instance.pair(uri: uri)
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
}
