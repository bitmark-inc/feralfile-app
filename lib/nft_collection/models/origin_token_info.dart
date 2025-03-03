//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//
import 'package:json_annotation/json_annotation.dart';

part 'origin_token_info.g.dart';

@JsonSerializable()
class OriginTokenInfo {
  OriginTokenInfo({
    required this.id,
    this.blockchain,
    this.fungible,
    this.contractType,
  });

  factory OriginTokenInfo.fromJson(Map<String, dynamic> json) =>
      _$OriginTokenInfoFromJson(json);
  String id;
  String? blockchain;
  bool? fungible;
  String? contractType;

  Map<String, dynamic> toJson() => _$OriginTokenInfoToJson(this);
}
