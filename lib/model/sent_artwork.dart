//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class SentArtwork {
  final String tokenID;
  final String address;
  final DateTime timestamp;
  final int sentQuantity;
  final bool isSentAll;

  SentArtwork(this.tokenID, this.address, this.timestamp, this.sentQuantity,
      this.isSentAll);

  factory SentArtwork.fromJson(Map<String, dynamic> json) => SentArtwork(
        json['tokenID'] as String,
        json['address'] as String,
        DateTime.parse(json['timestamp'] as String),
        (json['sentQuantity'] ?? 1) as int,
        (json['isSentAll'] ?? true) as bool,
      );

  Map<String, dynamic> toJson() => {
        'tokenID': tokenID,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
        'sentQuantity': sentQuantity,
        'isSentAll': isSentAll,
      };

  bool isHidden(
      {required String tokenID,
      required String address,
      required DateTime timestamp}) {
    if (this.tokenID == tokenID &&
        this.address == address &&
        this.timestamp.isAfter(timestamp)) {
      return true;
    }
    return false;
  }
}
