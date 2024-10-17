//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/graphql/account_settings/setting_object.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:nft_collection/models/address_index.dart';

enum ConnectionType {
  beaconP2PPeer, // Autonomy connect to TZ Dapp
  manuallyAddress,
  manuallyIndexerTokenID,
  dappConnect2,
}

extension RawValue on ConnectionType {
  String get rawValue => toString().split('.').last;
}

class Connection implements SettingObject {
  @override
  String key;
  String name;
  String data; // jsonData
  String connectionType;
  String accountNumber;
  DateTime createdAt;
  int? accountOrder;
  bool isHidden;

  /* Data
  enum ConnectionType {
    walletConnect, => WCConnectedSession
    dappConnect, => WalletConnectConnection
    beaconP2PPeer, => BeaconConnectConnection
    walletBeacon, => TezosConnection
    feralFileToken, => FeralFileConnection
    feralFileWeb3, => FeralFileWeb3Connection
    ledger => LedgerConnection; accountNumbes is the list joins("||")
  }
  */

  Connection({
    required this.key,
    required this.name,
    required this.data,
    required this.connectionType,
    required this.accountNumber,
    required this.createdAt,
    this.accountOrder,
    this.isHidden = false,
  });

  Connection copyWith({
    String? key,
    String? name,
    String? data,
    String? connectionType,
    String? accountNumber,
    DateTime? createdAt,
    int? accountOrder,
    bool? isHidden,
  }) =>
      Connection(
        key: key ?? this.key,
        name: name ?? this.name,
        data: data ?? this.data,
        connectionType: connectionType ?? this.connectionType,
        accountNumber: accountNumber ?? this.accountNumber,
        createdAt: createdAt ?? this.createdAt,
        accountOrder: accountOrder ?? this.accountOrder,
        isHidden: isHidden ?? this.isHidden,
      );

  bool get isViewing => !isHidden;

  BeaconConnectConnection? get beaconConnectConnection {
    if (connectionType != ConnectionType.beaconP2PPeer.rawValue) {
      return null;
    }

    final jsonData = json.decode(data);
    return BeaconConnectConnection.fromJson(jsonData);
  }

  String? get wc2ConnectedSession {
    if (connectionType != ConnectionType.dappConnect2.rawValue) {
      return null;
    }
    return data;
  }

  String get appName {
    if (beaconConnectConnection != null) {
      return beaconConnectConnection?.peer.name ?? '';
    }

    if (wc2ConnectedSession != null) {
      return name;
    }

    return '';
  }

  List<String> get accountNumbers => accountNumber.split('||');

  List<AddressIndex> get addressIndexes => accountNumbers
      .map((e) => AddressIndex(address: e, createdAt: createdAt))
      .toList();

  @override
  bool operator ==(covariant Connection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.key == key &&
        other.name == name &&
        other.data == data &&
        other.connectionType == connectionType &&
        other.accountNumber == accountNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      name.hashCode ^
      data.hashCode ^
      connectionType.hashCode ^
      accountNumber.hashCode ^
      createdAt.hashCode;

  // fromJson, toJson methods
  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
        key: json['key'] as String,
        name: json['name'] as String,
        data: json['data'] as String,
        connectionType: json['connectionType'] as String,
        accountNumber: json['accountNumber'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        accountOrder: json['accountOrder'] as int?,
        isHidden: json['isHidden'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'data': data,
        'connectionType': connectionType,
        'accountNumber': accountNumber,
        'createdAt': createdAt.toIso8601String(),
        'accountOrder': accountOrder,
        'isHidden': isHidden,
      };

  @override
  Map<String, String> get toKeyValue => {
        'key': key,
        'value': value,
      };

  @override
  String get value => jsonEncode(toJson());
}
