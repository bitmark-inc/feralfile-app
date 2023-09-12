//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:floor/floor.dart';

import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:nft_collection/models/address_index.dart';

enum ConnectionType {
  beaconP2PPeer, // Autonomy connect to TZ Dapp
  manuallyAddress,
  manuallyIndexerTokenID,
  walletConnect2, // Autonomy connect
  dappConnect2,
}

extension RawValue on ConnectionType {
  String get rawValue => toString().split('.').last;
}

@entity
class Connection {
  @primaryKey
  String key;
  String name;
  String data; // jsonData
  String connectionType;
  String accountNumber;
  DateTime createdAt;

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
  });

  Connection copyWith({
    String? key,
    String? name,
    String? data,
    String? connectionType,
    String? accountNumber,
    DateTime? createdAt,
  }) {
    return Connection(
      key: key ?? this.key,
      name: name ?? this.name,
      data: data ?? this.data,
      connectionType: connectionType ?? this.connectionType,
      accountNumber: accountNumber ?? this.accountNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  BeaconConnectConnection? get beaconConnectConnection {
    if (connectionType != ConnectionType.beaconP2PPeer.rawValue) return null;

    final jsonData = json.decode(data);
    return BeaconConnectConnection.fromJson(jsonData);
  }

  String? get wc2ConnectedSession {
    if (connectionType != ConnectionType.walletConnect2.rawValue &&
        connectionType != ConnectionType.dappConnect2.rawValue) return null;
    return data;
  }

  String get appName {
    if (beaconConnectConnection != null) {
      return beaconConnectConnection?.peer.name ?? "";
    }

    if (wc2ConnectedSession != null) {
      return name;
    }

    return "";
  }

  List<String> get accountNumbers {
    return accountNumber.split("||");
  }

  List<AddressIndex> get addressIndexes {
    return accountNumbers
        .map((e) => AddressIndex(address: e, createdAt: createdAt))
        .toList();
  }

  @override
  bool operator ==(covariant Connection other) {
    if (identical(this, other)) return true;

    return other.key == key &&
        other.name == name &&
        other.data == data &&
        other.connectionType == connectionType &&
        other.accountNumber == accountNumber &&
        other.createdAt == createdAt;
  }

  static Connection? getManuallyAddress(String? address) {
    if (address == null) return null;
    String checkAddress = address;
    final cryptoType = CryptoType.fromAddress(address);
    if (cryptoType == CryptoType.ETH) {
      checkAddress = address.getETHEip55Address();
    }
    if (cryptoType == CryptoType.UNKNOWN) return null;
    return Connection(
        key: checkAddress,
        name: cryptoType.source,
        data: "",
        connectionType: ConnectionType.manuallyAddress.rawValue,
        accountNumber: checkAddress,
        createdAt: DateTime.now());
  }

  @override
  int get hashCode {
    return key.hashCode ^
        name.hashCode ^
        data.hashCode ^
        connectionType.hashCode ^
        accountNumber.hashCode ^
        createdAt.hashCode;
  }
}
