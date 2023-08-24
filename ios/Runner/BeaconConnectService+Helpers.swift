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
        .error(ErrorBeaconResponse(id: id, version: version, destination: origin, errorType: .aborted))
    }
}

extension OperationTezosRequest {
    func done(txHash: String) -> TezosBeaconResponse {
        .blockchain(
            .operation(OperationTezosResponse(from: self, transactionHash: txHash))
        )
    }

    func decline() -> TezosBeaconResponse {
        .error(ErrorBeaconResponse(id: id, version: version, destination: origin, errorType: .aborted))
    }
}
