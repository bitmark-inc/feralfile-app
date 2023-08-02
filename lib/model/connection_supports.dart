//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

import 'package:autonomy_flutter/model/ff_account.dart';

import 'p2p_peer.dart';

part 'connection_supports.g.dart';

@JsonSerializable()
class FeralFileConnection {
  String source;
  FFAccount ffAccount;

  FeralFileConnection({
    required this.source,
    required this.ffAccount,
  });

  factory FeralFileConnection.fromJson(Map<String, dynamic> json) =>
      _$FeralFileConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileConnectionToJson(this);
}

@JsonSerializable()
class FeralFileWeb3Connection {
  String personaAddress;
  String source;
  FFAccount ffAccount;

  FeralFileWeb3Connection({
    required this.personaAddress,
    required this.source,
    required this.ffAccount,
  });

  factory FeralFileWeb3Connection.fromJson(Map<String, dynamic> json) =>
      _$FeralFileWeb3ConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$FeralFileWeb3ConnectionToJson(this);
}

@JsonSerializable()
class BeaconConnectConnection {
  String personaUuid;
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

@JsonSerializable()
class LedgerConnection {
  String ledgerName;
  String ledgerUUID;
  List<String> etheremAddress;
  List<String> tezosAddress;

  LedgerConnection({
    required this.ledgerName,
    required this.ledgerUUID,
    required this.etheremAddress,
    required this.tezosAddress,
  });

  factory LedgerConnection.fromJson(Map<String, dynamic> json) =>
      _$LedgerConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$LedgerConnectionToJson(this);
}
