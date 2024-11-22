//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class BlockchainIdentity {
  String accountNumber;
  String blockchain;
  String name;

  BlockchainIdentity(this.accountNumber, this.blockchain, this.name);

  BlockchainIdentity.fromJson(Map<String, dynamic> json)
      : accountNumber = json['accountNumber'] as String,
        blockchain = json['blockchain'] as String,
        name = json['name'] as String;
}
