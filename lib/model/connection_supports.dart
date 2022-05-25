//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';
import 'package:wallet_connect/wc_session_store.dart';

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
class WalletConnectConnection {
  String personaUuid;
  WCSessionStore sessionStore;

  WalletConnectConnection({
    required this.personaUuid,
    required this.sessionStore,
  });

  factory WalletConnectConnection.fromJson(Map<String, dynamic> json) =>
      _$WalletConnectConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$WalletConnectConnectionToJson(this);
}

@JsonSerializable()
class BeaconConnectConnection {
  String personaUuid;
  P2PPeer peer;

  BeaconConnectConnection({
    required this.personaUuid,
    required this.peer,
  });

  factory BeaconConnectConnection.fromJson(Map<String, dynamic> json) =>
      _$BeaconConnectConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$BeaconConnectConnectionToJson(this);
}
