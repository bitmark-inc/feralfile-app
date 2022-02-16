import 'dart:convert';

import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:floor/floor.dart';

enum ConnectionType {
  walletConnect,
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
    final jsonData = json.decode(this.data);
    return FeralFileConnection.fromJson(jsonData);
  }
}
