//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:floor/floor.dart';
//ignore_for_file: lines_longer_than_80_chars

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query('SELECT * FROM Connection WHERE connectionType NOT IN '
      '("dappConnect", "dappConnect2", "walletConnect2", "beaconP2PPeer", '
      '"manuallyIndexerTokenID")')
  Future<List<Connection>> getLinkedAccounts();

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

  @Query('DELETE FROM Connection')
  Future<void> removeAll();

  @delete
  Future<void> deleteConnection(Connection connection);

  @delete
  Future<void> deleteConnections(List<Connection> connections);

  @Query('DELETE FROM Connection WHERE `key` LIKE :topic')
  Future<void> deleteConnectionsByTopic(String topic);

  @Query('DELETE FROM Connection WHERE connectionType = :type')
  Future<void> deleteConnectionsByType(String type);

  @update
  Future<void> updateConnection(Connection connection);
}
