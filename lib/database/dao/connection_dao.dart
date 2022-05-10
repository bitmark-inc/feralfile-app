import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:floor/floor.dart';

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query(
      'SELECT * FROM Connection WHERE connectionType NOT IN ("dappConnect", "beaconP2PPeer", "manuallyIndexerTokenID")')
  Future<List<Connection>> getLinkedAccounts();

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
