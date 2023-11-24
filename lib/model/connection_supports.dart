//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

import 'p2p_peer.dart';

part 'connection_supports.g.dart';

@JsonSerializable()
class BeaconConnectConnection {
  String personaUuid;
  @JsonKey(defaultValue: 0)
  int index;
  P2PPeer peer;

  BeaconConnectConnection({
    required this.personaUuid,
    required this.index,
    required this.peer,
  });

  factory BeaconConnectConnection.fromJson(Map<String, dynamic> json) =>
      _$BeaconConnectConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$BeaconConnectConnectionToJson(this);
}
