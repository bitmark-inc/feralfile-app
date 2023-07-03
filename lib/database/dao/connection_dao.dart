//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/model/connection_supports.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:floor/floor.dart';

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query(
      'SELECT * FROM Connection WHERE connectionType NOT IN ("dappConnect", "dappConnect2", "walletConnect2", "beaconP2PPeer", "manuallyIndexerTokenID")')
  Future<List<Connection>> getLinkedAccounts();

  // getUpdatedLinkedAccounts:
  //   - format ETH address as checksum address
  Future<List<Connection>> getUpdatedLinkedAccounts() async {
    final linkedAccounts = await getLinkedAccounts();

    final deperatedLedgerConnections = linkedAccounts.where((element) =>
        element.connectionType == 'ledgerEthereum' ||
        element.connectionType == 'ledgerTezos');

    if (deperatedLedgerConnections.isNotEmpty) {
      await _migrateDeperatedLedger(deperatedLedgerConnections.toList());
      return getUpdatedLinkedAccounts();
    }

    return linkedAccounts.map((e) {
      switch (e.connectionType) {
        case 'walletConnect':
        case 'walletBrowserConnect':
          return e.copyWith(
              accountNumber: e.accountNumber.getETHEip55Address());
        default:
          return e;
      }
    }).toList();
  }

  @Query(
      'SELECT * FROM Connection WHERE connectionType IN ("dappConnect", "dappConnect2", "beaconP2PPeer")')
  Future<List<Connection>> getRelatedPersonaConnections();

  @Query(
      'SELECT * FROM Connection WHERE connectionType = :type ORDER BY createdAt DESC')
  Future<List<Connection>> getConnectionsByType(String type);

  @Query(
      'SELECT * FROM Connection WHERE accountNumber = :accountNumber COLLATE NOCASE')
  Future<List<Connection>> getConnectionsByAccountNumber(String accountNumber);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertConnection(Connection connection);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertConnections(List<Connection> connections);

  @Query('SELECT * FROM Connection WHERE key = :key')
  Future<Connection?> findById(String key);

  @Query('DELETE FROM Connection')
  Future<void> removeAll();

  @delete
  Future<void> deleteConnection(Connection connection);

  @Query(
      'DELETE FROM Connection WHERE accountNumber = :accountNumber COLLATE NOCASE')
  Future<void> deleteConnectionsByAccountNumber(String accountNumber);

  @Query('DELETE FROM Connection WHERE connectionType = :type')
  Future<void> deleteConnectionsByType(String type);

  @update
  Future<void> updateConnection(Connection connection);

  // migrate: combine ledgerEthereum and ledgerTezos into ledger
  Future _migrateDeperatedLedger(List<Connection> connections) async {
    for (final oldConnection in connections) {
      final jsonData = json.decode(oldConnection.data) as Map<String, dynamic>;
      var ledgerName = jsonData['ledger'] ?? 'unknown';
      var ledgerUUID = jsonData['ledger_uuid'] as String;

      var data = LedgerConnection(
          ledgerName: ledgerName,
          ledgerUUID: ledgerUUID,
          etheremAddress: [],
          tezosAddress: []);

      final existingConnection = await findById(ledgerUUID);
      if (existingConnection != null) {
        data = LedgerConnection.fromJson(json.decode(existingConnection.data));
      }

      switch (oldConnection.connectionType) {
        case 'ledgerEthereum':
          data.etheremAddress
              .add(oldConnection.accountNumber.getETHEip55Address());
          break;
        case 'ledgerTezos':
          data.tezosAddress.add(oldConnection.accountNumber);
          break;
        default:
          break;
      }

      final newConnection = Connection(
        key: ledgerUUID,
        name: ledgerName,
        data: json.encode(data),
        connectionType: ConnectionType.ledger.rawValue,
        accountNumber: (data.etheremAddress + data.tezosAddress).join("||"),
        createdAt: existingConnection?.createdAt ?? DateTime.now(),
      );

      await deleteConnection(oldConnection);
      await insertConnection(newConnection);
    }
  }
}
