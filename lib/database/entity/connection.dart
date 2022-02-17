import 'dart:convert';

import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/tezos_connection.dart';
import 'package:autonomy_flutter/service/wallet_connect_dapp_service/wc_connected_session.dart';
import 'package:floor/floor.dart';

enum ConnectionType {
  walletConnect, // Autonomy connect to Wallet
  dappConnect, // Autonomy connect to Dapp
  beaconP2PPeer,
  walletBeacon,
  feralFileToken,
  feralFileWeb3,
}

extension RawValue on ConnectionType {
  String get rawValue => this.toString().split('.').last;
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
      accountNumber: ffAccount.accountNumber,
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

  Connection copyFFWith(FFAccount ffAccount) {
    final ffConnection = this.ffConnection;
    if (ffConnection == null) {
      throw Exception("incorrectDataFlow");
    }
    final newFFConnection =
        FeralFileConnection(source: ffConnection.source, ffAccount: ffAccount);

    return this
        .copyWith(name: ffAccount.alias, data: json.encode(newFFConnection));
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

    final jsonData = json.decode(this.data);
    return FeralFileConnection.fromJson(jsonData);
  }

  WalletConnectConnection? get wcConnection {
    if (connectionType != ConnectionType.dappConnect.rawValue) return null;

    final jsonData = json.decode(this.data);
    return WalletConnectConnection.fromJson(jsonData);
  }

  TezosConnection? get walletBeaconConnection {
    if (connectionType != ConnectionType.walletBeacon.rawValue) return null;

    final jsonData = json.decode(this.data);
    return TezosConnection.fromJson(jsonData);
  }

  WCConnectedSession? get wcConnectedSession {
    if (connectionType != ConnectionType.walletConnect.rawValue) return null;

    final jsonData = json.decode(this.data);
    return WCConnectedSession.fromJson(jsonData);
  }
}
