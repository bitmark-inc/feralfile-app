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
