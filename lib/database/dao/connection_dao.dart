//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:floor/floor.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query(
      'SELECT * FROM Connection WHERE connectionType NOT IN ("dappConnect", "beaconP2PPeer", "manuallyIndexerTokenID")')
  Future<List<Connection>> getLinkedAccounts();

  // getUpdatedLinkedAccounts:
  //   - format ETH address as checksum address
  Future<List<Connection>> getUpdatedLinkedAccounts() async {
    final linkedAccounts = await getLinkedAccounts();
    return linkedAccounts.map((e) {
      switch (e.connectionType) {
        case 'walletConnect':
        case 'walletBrowserConnect':
        case 'ledgerEthereum':
          return e.copyWith(
              accountNumber: e.accountNumber.getETHEip55Address());
        default:
          return e;
      }
    }).toList();
  }

  @Query(
      'SELECT * FROM Connection WHERE connectionType IN ("dappConnect", "beaconP2PPeer")')
  Future<List<Connection>> getRelatedPersonaConnections();

  @Query('SELECT * FROM Connection WHERE connectionType = :type')
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
}
