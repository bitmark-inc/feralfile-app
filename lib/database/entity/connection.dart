//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:floor/floor.dart';

import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:nft_collection/models/address_index.dart';

enum ConnectionType {
  walletConnect, // Autonomy connect to ETH Wallet
  walletBrowserConnect, // Autonomy connect to ETH Browser wallet
  dappConnect, // Autonomy connect to ETH Dapp
  beaconP2PPeer, // Autonomy connect to TZ Dapp
  walletBeacon, // Autonomy connect to TZ Wallet
  feralFileToken, // Autonomy connect to FF by read-only token
  feralFileWeb3, // Autonomy connect to FF by Web3
  ledger, // Autonomy connect to Ledger: ETH, TZ
  manuallyAddress,
  manuallyIndexerTokenID,
  walletConnect2,
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

  factory Connection.fromFFToken(
      String token, String source, FFAccount ffAccount) {
    final ffConnection =
        FeralFileConnection(source: source, ffAccount: ffAccount);

    return Connection(
      key: token,
      name: ffAccount.alias,
      data: json.encode(ffConnection),
      connectionType: ConnectionType.feralFileToken.rawValue,
      accountNumber: ffAccount.id,
      createdAt: DateTime.now(),
    );
  }

  factory Connection.fromETHWallet(WCConnectedSession connectedSession) {
    return Connection(
      key: connectedSession.accounts.first,
      name: "",
      data: json.encode(connectedSession),
      connectionType: ConnectionType.walletConnect.rawValue,
      accountNumber: connectedSession.accounts.first,
      createdAt: DateTime.now(),
    );
  }

  factory Connection.fromFFWeb3(
      String topic, String source, String personaAddress, FFAccount ffAccount) {
    final ffWeb3Connection = FeralFileWeb3Connection(
        personaAddress: personaAddress, source: source, ffAccount: ffAccount);

    return Connection(
      key: topic,
      name: ffAccount.alias,
      data: json.encode(ffWeb3Connection),
      connectionType: ConnectionType.feralFileWeb3.rawValue,
      accountNumber: ffAccount.id,
      createdAt: DateTime.now(),
    );
  }

  Connection copyFFWith(FFAccount ffAccount) {
    final ffConnection = this.ffConnection;
    final ffWeb3Connection = this.ffWeb3Connection;

    var mergedName = ffAccount.alias;
    if (name.isNotEmpty) {
      mergedName = name;
    }

    if (ffConnection != null) {
      final newFFConnection = FeralFileConnection(
          source: ffConnection.source, ffAccount: ffAccount);

      return copyWith(name: mergedName, data: json.encode(newFFConnection));
    } else if (ffWeb3Connection != null) {
      final newFFWeb3Connection = FeralFileWeb3Connection(
          personaAddress: ffWeb3Connection.personaAddress,
          source: ffWeb3Connection.source,
          ffAccount: ffAccount);

      return copyWith(name: mergedName, data: json.encode(newFFWeb3Connection));
    } else {
      throw Exception("incorrectDataFlow");
    }
  }

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

  FeralFileConnection? get ffConnection {
    if (connectionType != ConnectionType.feralFileToken.rawValue) return null;

    final jsonData = json.decode(data);
    return FeralFileConnection.fromJson(jsonData);
  }

  FeralFileWeb3Connection? get ffWeb3Connection {
    if (connectionType != ConnectionType.feralFileWeb3.rawValue) return null;

    final jsonData = json.decode(data);
    return FeralFileWeb3Connection.fromJson(jsonData);
  }

  WalletConnectConnection? get wcConnection {
    if (connectionType != ConnectionType.dappConnect.rawValue) return null;

    final jsonData = json.decode(data);
    return WalletConnectConnection.fromJson(jsonData);
  }

  TezosConnection? get walletBeaconConnection {
    if (connectionType != ConnectionType.walletBeacon.rawValue) return null;

    final jsonData = json.decode(data);
    return TezosConnection.fromJson(jsonData);
  }

  BeaconConnectConnection? get beaconConnectConnection {
    if (connectionType != ConnectionType.beaconP2PPeer.rawValue) return null;

    final jsonData = json.decode(data);
    return BeaconConnectConnection.fromJson(jsonData);
  }

  WCConnectedSession? get wcConnectedSession {
    if (connectionType != ConnectionType.walletConnect.rawValue) return null;

    final jsonData = json.decode(data);
    return WCConnectedSession.fromJson(jsonData);
  }

  String? get wc2ConnectedSession {
    if (connectionType != ConnectionType.walletConnect2.rawValue &&
        connectionType != ConnectionType.dappConnect2.rawValue) return null;
    return data;
  }

  LedgerConnection? get ledgerConnection {
    if (connectionType != ConnectionType.ledger.rawValue) return null;

    final jsonData = json.decode(data);
    return LedgerConnection.fromJson(jsonData);
  }

  String get appName {
    if (wcConnection != null) {
      return wcConnection?.sessionStore.remotePeerMeta.name ?? "";
    }

    if (beaconConnectConnection != null) {
      return beaconConnectConnection?.peer.name ?? "";
    }

    if (wc2ConnectedSession != null) {
      return name;
    }

    return "";
  }

  List<String> get accountNumbers {
    switch (connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        var addresses = [accountNumber];
        final ffAccount =
            ffConnection?.ffAccount ?? ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) addresses.add(ethereumAddress);
        if (tezosAddress != null) addresses.add(tezosAddress);

        return addresses;

      default:
        return accountNumber.split("||");
    }
  }

  List<AddressIndex> get addressIndexes {
    switch (connectionType) {
      case 'feralFileWeb3':
      case 'feralFileToken':
        var addresses = [
          AddressIndex(address: accountNumber, createdAt: createdAt)
        ];
        final ffAccount =
            ffConnection?.ffAccount ?? ffWeb3Connection?.ffAccount;
        final ethereumAddress = ffAccount?.ethereumAddress;
        final tezosAddress = ffAccount?.tezosAddress;

        if (ethereumAddress != null) {
          addresses.add(
              AddressIndex(address: ethereumAddress, createdAt: createdAt));
        }
        if (tezosAddress != null) {
          addresses
              .add(AddressIndex(address: tezosAddress, createdAt: createdAt));
        }

        return addresses;
      case 'ledger':
        final data = ledgerConnection;
        final ethereumAddress = data?.etheremAddress.firstOrNull;
        final tezosAddress = data?.tezosAddress.firstOrNull;
        List<AddressIndex> addresses = [];
        if (ethereumAddress != null) {
          addresses.add(
              AddressIndex(address: ethereumAddress, createdAt: createdAt));
        }
        if (tezosAddress != null) {
          addresses
              .add(AddressIndex(address: tezosAddress, createdAt: createdAt));
        }
        return addresses;
      default:
        return accountNumber
            .split("||")
            .map((e) => AddressIndex(address: e, createdAt: createdAt))
            .toList();
    }
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
