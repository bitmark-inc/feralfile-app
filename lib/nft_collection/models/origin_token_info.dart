//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

class OriginTokenInfo {
  OriginTokenInfo({
    required this.id,
    this.blockchain,
    this.fungible,
    this.contractType,
  });

  factory OriginTokenInfo.fromJson(Map<String, dynamic> json) =>
      OriginTokenInfo(
        id: json['id'] as String,
        blockchain: json['blockchain'] as String?,
        fungible: json['fungible'] as bool?,
        contractType: json['contractType'] as String?,
      );

  String id;
  String? blockchain;
  bool? fungible;
  String? contractType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'blockchain': blockchain,
        'fungible': fungible,
        'contractType': contractType,
      };
}
