//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:json_annotation/json_annotation.dart';

part 'tezos_connection.g.dart';

@JsonSerializable()
class TezosConnection {
  TezosConnection({
    required this.address,
    required this.peer,
    required this.permissionResponse,
  });

  String address;
  Peer peer;
  PermissionResponse permissionResponse;

  factory TezosConnection.fromJson(Map<String, dynamic> json) =>
      _$TezosConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$TezosConnectionToJson(this);
}

@JsonSerializable()
class Peer {
  Peer({
    required this.relayServer,
    required this.id,
    required this.kind,
    required this.publicKey,
    required this.name,
    required this.version,
  });

  String relayServer;
  String id;
  String? kind;
  String publicKey;
  String name;
  String version;

  factory Peer.fromJson(Map<String, dynamic> json) => _$PeerFromJson(json);

  Map<String, dynamic> toJson() => _$PeerToJson(this);
}

@JsonSerializable()
class PermissionResponse {
  String id;
  String version;
  RequestOrigin requestOrigin;
  List<String> scopes;
  String? publicKey;
  TezosNetwork? network;
  BeaconAccount? account;

  PermissionResponse({
    required this.id,
    required this.version,
    required this.requestOrigin,
    required this.scopes,
    this.publicKey,
    this.network,
    this.account,
  });

  factory PermissionResponse.fromJson(Map<String, dynamic> json) =>
      _$PermissionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PermissionResponseToJson(this);
}

@JsonSerializable()
class BeaconAccount {
  String accountId;
  TezosNetwork network;
  String publicKey;
  String address;

  BeaconAccount({
    required this.accountId,
    required this.network,
    required this.publicKey,
    required this.address,
  });

  factory BeaconAccount.fromJson(Map<String, dynamic> json) =>
      _$BeaconAccountFromJson(json);

  Map<String, dynamic> toJson() => _$BeaconAccountToJson(this);
}

@JsonSerializable()
class TezosNetwork {
  TezosNetwork({
    required this.type,
  });

  String type;

  factory TezosNetwork.fromJson(Map<String, dynamic> json) =>
      _$TezosNetworkFromJson(json);

  Map<String, dynamic> toJson() => _$TezosNetworkToJson(this);
}

@JsonSerializable()
class RequestOrigin {
  RequestOrigin({
    required this.kind,
    required this.id,
  });

  String? kind;
  String id;

  factory RequestOrigin.fromJson(Map<String, dynamic> json) =>
      _$RequestOriginFromJson(json);

  Map<String, dynamic> toJson() => _$RequestOriginToJson(this);
}
