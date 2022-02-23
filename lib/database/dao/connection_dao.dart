import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:floor/floor.dart';

@dao
abstract class ConnectionDao {
  @Query('SELECT * FROM Connection')
  Future<List<Connection>> getConnections();

  @Query(
      'SELECT * FROM Connection WHERE connectionType NOT IN ("dappConnect", "beaconP2PPeer")')
  Future<List<Connection>> getLinkedAccounts();

  @Query(
      'SELECT * FROM Connection WHERE connectionType IN ("dappConnect", "beaconP2PPeer")')
  Future<List<Connection>> getRelatedPersonaConnections();

  @Query('SELECT * FROM Connection WHERE connectionType = :type')
  Future<List<Connection>> getConnectionsByType(String type);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertConnection(Connection connection);

  @Query('SELECT * FROM Connection WHERE key = :key')
  Future<Connection?> findById(String key);

  @Query('DELETE FROM Connection')
  Future<void> removeAll();

  @delete
  Future<void> deleteConnection(Connection connection);

  @Query('DELETE FROM Connection WHERE accountNumber = :accountNumber')
  Future<void> deleteConnectionsByAccountNumber(String accountNumber);

  @update
  Future<void> updateConnection(Connection connection);
}
