import 'dart:convert';

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/graphql/account_settings/account_settings_db.dart';

class ConnectionCloudObject {
  final AccountSettingsDB _accountSettingsDB;

  ConnectionCloudObject(this._accountSettingsDB);

  AccountSettingsDB get db => _accountSettingsDB;

  Future<void> deleteConnections(List<Connection> connections) =>
      _accountSettingsDB.delete(connections.map((e) => e.key).toList());

  Future<void> deleteConnectionsByTopic(String topic) async {
    final allConnections = getConnections();
    final connections =
        allConnections.where((element) => element.key.contains(topic)).toList();
    return await _accountSettingsDB
        .delete(connections.map((e) => e.key).toList());
  }

  Future<void> deleteConnectionsByType(String type) async {
    final allConnections = getConnections();
    final connections = allConnections
        .where((element) => element.connectionType == type)
        .toList();
    return await _accountSettingsDB
        .delete(connections.map((e) => e.key).toList());
  }

  List<Connection> getConnections() {
    final connections = _accountSettingsDB.values
        .map((e) => Connection.fromJson(jsonDecode(e)))
        .toList();
    return connections;
  }

  List<Connection> getConnectionsByAccountNumber(String accountNumber) {
    final allConnections = getConnections();
    return allConnections
        .where((element) =>
            element.accountNumber.toLowerCase() == accountNumber.toLowerCase())
        .toList();
  }

  List<Connection> getConnectionsByType(String type) {
    final allConnections = getConnections();
    final connections = allConnections
        .where((element) => element.connectionType == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return connections;
  }

  List<Connection> getLinkedAccounts() =>
      getConnectionsByType(ConnectionType.manuallyAddress.rawValue);

  List<Connection> getWc2Connections() {
    final allConnections = getConnections();
    return allConnections
        .where((element) => element.connectionType == 'dappConnect2')
        .toList();
  }

  Future<void> writeConnection(Connection connection) =>
      writeConnections([connection]);

  Future<void> writeConnections(List<Connection> connections) =>
      _accountSettingsDB.write(connections.map((e) => e.toKeyValue).toList());
}
