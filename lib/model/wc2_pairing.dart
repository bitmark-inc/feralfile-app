//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wc2_pairing.g.dart';

@JsonSerializable()
class Wc2Pairing {
  final String topic;
  @JsonKey(defaultValue: 0)
  final int expiry;
  final AppMetadata? peerAppMetaData;

  Wc2Pairing(
    this.topic,
    this.expiry,
    this.peerAppMetaData,
  );

  factory Wc2Pairing.fromJson(Map<String, dynamic> json) =>
      _$Wc2PairingFromJson(json);

  Map<String, dynamic> toJson() => _$Wc2PairingToJson(this);
}
