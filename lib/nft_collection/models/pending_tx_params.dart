//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class PendingTxParams {
  PendingTxParams({
    required this.blockchain,
    required this.id,
    required this.contractAddress,
    required this.ownerAccount,
    required this.pendingTx,
    required this.timestamp,
    required this.signature,
    this.publicKey,
  });

  final String blockchain;
  final String id;
  final String contractAddress;
  final String ownerAccount;
  final String pendingTx;
  final String timestamp;
  final String signature;
  final String? publicKey;

  Map<String, dynamic> toJson() => {
        'blockchain': blockchain,
        'id': id,
        'contractAddress': contractAddress,
        'ownerAccount': ownerAccount,
        'pendingTx': pendingTx,
        'timestamp': timestamp,
        'signature': signature,
        'publicKey': publicKey,
      };
}
