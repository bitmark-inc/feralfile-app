//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:floor/floor.dart';

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query('SELECT * FROM Connection WHERE connectionType NOT IN '
      '("dappConnect", "dappConnect2", "walletConnect2", "beaconP2PPeer", '
      '"manuallyIndexerTokenID")')
  Future<List<Connection>> getLinkedAccounts();

  // getUpdatedLinkedAccounts:
  //   - format ETH address as checksum address
  Future<List<Connection>> getUpdatedLinkedAccounts() async {
    final linkedAccounts = await getLinkedAccounts();

    final deprecatedConnections = linkedAccounts
        .where((element) => element.connectionType != 'manuallyAddress');

    if (deprecatedConnections.isNotEmpty) {
      await _migrateDeprecatedConnections(deprecatedConnections.toList());
      return getUpdatedLinkedAccounts();
    }

    return linkedAccounts;
  }

  @Query('SELECT * FROM Connection WHERE connectionType IN '
      '("dappConnect", "dappConnect2", "beaconP2PPeer")')
  Future<List<Connection>> getRelatedPersonaConnections();

  @Query('SELECT * FROM Connection WHERE connectionType IN '
      '("dappConnect2", "walletConnect2")')
  Future<List<Connection>> getWc2Connections();

  @Query('SELECT * FROM Connection WHERE connectionType = :type '
      'ORDER BY createdAt DESC')
  Future<List<Connection>> getConnectionsByType(String type);

  @Query('SELECT * FROM Connection WHERE accountNumber = :accountNumber '
      'COLLATE NOCASE')
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

  @delete
  Future<void> deleteConnections(List<Connection> connections);

  @Query('DELETE FROM Connection WHERE accountNumber = :accountNumber '
      'COLLATE NOCASE')
  Future<void> deleteConnectionsByAccountNumber(String accountNumber);

  @Query('DELETE FROM Connection WHERE connectionType = :type')
  Future<void> deleteConnectionsByType(String type);

  @update
  Future<void> updateConnection(Connection connection);

  // migrate: combine ledgerEthereum and ledgerTezos into ledger
  Future _migrateDeprecatedConnections(List<Connection> connections) async {
    final List<String> address = [];
    for (final oldConnection in connections) {
      switch (oldConnection.connectionType) {
        case 'ledger':
          final jsonData = json.decode(oldConnection.data);
          // there is a typo in creating connections for ledger code:
          // etheremAddress
          final etheremAddress = (jsonData['etheremAddress'] == null
                  ? []
                  : (jsonData['etheremAddress'] as List<dynamic>))
              .map((e) => e as String)
              .toList();
          final tezosAddress = (jsonData['tezosAddress'] == null
                  ? []
                  : (jsonData['tezosAddress'] as List<dynamic>))
              .map((e) => e as String)
              .toList();
          address.addAll(etheremAddress);
          address.addAll(tezosAddress);
          break;
        default:
          address.addAll(oldConnection.accountNumbers);
      }
      await deleteConnection(oldConnection);
    }

    final List<Connection> newConnections = [];
    for (final address in address) {
      final newConnection = Connection.getManuallyAddress(address);
      newConnection != null ? newConnections.add(newConnection) : null;
    }
    await insertConnections(newConnections);
  }
}
