// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorCloudDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$CloudDatabaseBuilder databaseBuilder(String name) =>
      _$CloudDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$CloudDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$CloudDatabaseBuilder(null);
}

class _$CloudDatabaseBuilder {
  _$CloudDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$CloudDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$CloudDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<CloudDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$CloudDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$CloudDatabase extends CloudDatabase {
  _$CloudDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ConnectionDao? _connectionDaoInstance;

  WalletAddressDao? _addressDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 9,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Connection` (`key` TEXT NOT NULL, `name` TEXT NOT NULL, `data` TEXT NOT NULL, `connectionType` TEXT NOT NULL, `accountNumber` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `accountOrder` INTEGER, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WalletAddress` (`address` TEXT NOT NULL, `uuid` TEXT NOT NULL, `index` INTEGER NOT NULL, `cryptoType` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `isHidden` INTEGER NOT NULL, `name` TEXT, `accountOrder` INTEGER, PRIMARY KEY (`address`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ConnectionDao get connectionDao {
    return _connectionDaoInstance ??= _$ConnectionDao(database, changeListener);
  }

  @override
  WalletAddressDao get addressDao {
    return _addressDaoInstance ??= _$WalletAddressDao(database, changeListener);
  }
}

class _$ConnectionDao extends ConnectionDao {
  _$ConnectionDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _connectionInsertionAdapter = InsertionAdapter(
            database,
            'Connection',
            (Connection item) => <String, Object?>{
                  'key': item.key,
                  'name': item.name,
                  'data': item.data,
                  'connectionType': item.connectionType,
                  'accountNumber': item.accountNumber,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'accountOrder': item.accountOrder
                }),
        _connectionUpdateAdapter = UpdateAdapter(
            database,
            'Connection',
            ['key'],
            (Connection item) => <String, Object?>{
                  'key': item.key,
                  'name': item.name,
                  'data': item.data,
                  'connectionType': item.connectionType,
                  'accountNumber': item.accountNumber,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'accountOrder': item.accountOrder
                }),
        _connectionDeletionAdapter = DeletionAdapter(
            database,
            'Connection',
            ['key'],
            (Connection item) => <String, Object?>{
                  'key': item.key,
                  'name': item.name,
                  'data': item.data,
                  'connectionType': item.connectionType,
                  'accountNumber': item.accountNumber,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'accountOrder': item.accountOrder
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Connection> _connectionInsertionAdapter;

  final UpdateAdapter<Connection> _connectionUpdateAdapter;

  final DeletionAdapter<Connection> _connectionDeletionAdapter;

  @override
  Future<List<Connection>> getConnections() async {
    return _queryAdapter.queryList('SELECT * FROM Connection',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            accountOrder: row['accountOrder'] as int?));
  }

  @override
  Future<List<Connection>> getLinkedAccounts() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE connectionType NOT IN (\"dappConnect\", \"dappConnect2\", \"walletConnect2\", \"beaconP2PPeer\", \"manuallyIndexerTokenID\")',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            accountOrder: row['accountOrder'] as int?));
  }

  @override
  Future<List<Connection>> getWc2Connections() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE connectionType IN (\"dappConnect2\", \"walletConnect2\")',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            accountOrder: row['accountOrder'] as int?));
  }

  @override
  Future<List<Connection>> getConnectionsByType(String type) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE connectionType = ?1 ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => Connection(key: row['key'] as String, name: row['name'] as String, data: row['data'] as String, connectionType: row['connectionType'] as String, accountNumber: row['accountNumber'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), accountOrder: row['accountOrder'] as int?),
        arguments: [type]);
  }

  @override
  Future<List<Connection>> getConnectionsByAccountNumber(
      String accountNumber) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE accountNumber = ?1 COLLATE NOCASE',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            accountOrder: row['accountOrder'] as int?),
        arguments: [accountNumber]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Connection');
  }

  @override
  Future<void> deleteConnectionsByTopic(String topic) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Connection WHERE `key` LIKE ?1',
        arguments: [topic]);
  }

  @override
  Future<void> deleteConnectionsByType(String type) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Connection WHERE connectionType = ?1',
        arguments: [type]);
  }

  @override
  Future<void> insertConnection(Connection connection) async {
    await _connectionInsertionAdapter.insert(
        connection, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertConnections(List<Connection> connections) async {
    await _connectionInsertionAdapter.insertList(
        connections, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateConnection(Connection connection) async {
    await _connectionUpdateAdapter.update(connection, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteConnection(Connection connection) async {
    await _connectionDeletionAdapter.delete(connection);
  }

  @override
  Future<void> deleteConnections(List<Connection> connections) async {
    await _connectionDeletionAdapter.deleteList(connections);
  }
}

class _$WalletAddressDao extends WalletAddressDao {
  _$WalletAddressDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _walletAddressInsertionAdapter = InsertionAdapter(
            database,
            'WalletAddress',
            (WalletAddress item) => <String, Object?>{
                  'address': item.address,
                  'uuid': item.uuid,
                  'index': item.index,
                  'cryptoType': item.cryptoType,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'isHidden': item.isHidden ? 1 : 0,
                  'name': item.name,
                  'accountOrder': item.accountOrder
                }),
        _walletAddressUpdateAdapter = UpdateAdapter(
            database,
            'WalletAddress',
            ['address'],
            (WalletAddress item) => <String, Object?>{
                  'address': item.address,
                  'uuid': item.uuid,
                  'index': item.index,
                  'cryptoType': item.cryptoType,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'isHidden': item.isHidden ? 1 : 0,
                  'name': item.name,
                  'accountOrder': item.accountOrder
                }),
        _walletAddressDeletionAdapter = DeletionAdapter(
            database,
            'WalletAddress',
            ['address'],
            (WalletAddress item) => <String, Object?>{
                  'address': item.address,
                  'uuid': item.uuid,
                  'index': item.index,
                  'cryptoType': item.cryptoType,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'isHidden': item.isHidden ? 1 : 0,
                  'name': item.name,
                  'accountOrder': item.accountOrder
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WalletAddress> _walletAddressInsertionAdapter;

  final UpdateAdapter<WalletAddress> _walletAddressUpdateAdapter;

  final DeletionAdapter<WalletAddress> _walletAddressDeletionAdapter;

  @override
  Future<List<WalletAddress>> getAllAddresses() async {
    return _queryAdapter.queryList('SELECT * FROM WalletAddress',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?));
  }

  @override
  Future<WalletAddress?> findByAddress(String address) async {
    return _queryAdapter.query('SELECT * FROM WalletAddress WHERE address = ?1',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [address]);
  }

  @override
  Future<List<WalletAddress>> findByWalletID(String uuid) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WalletAddress WHERE uuid = ?1',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [uuid]);
  }

  @override
  Future<List<WalletAddress>> findAddressesWithHiddenStatus(
      bool isHidden) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WalletAddress WHERE isHidden = ?1',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [isHidden ? 1 : 0]);
  }

  @override
  Future<List<WalletAddress>> getAddresses(
    String uuid,
    String cryptoType,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WalletAddress WHERE uuid = ?1 AND cryptoType = ?2',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [uuid, cryptoType]);
  }

  @override
  Future<List<WalletAddress>> getAddressesByType(String cryptoType) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WalletAddress WHERE cryptoType = ?1',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [cryptoType]);
  }

  @override
  Future<void> setAddressIsHidden(
    String address,
    bool isHidden,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE WalletAddress SET isHidden = ?2 WHERE address = ?1',
        arguments: [address, isHidden ? 1 : 0]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM WalletAddress');
  }

  @override
  Future<void> deleteAddressesByPersona(String uuid) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM WalletAddress WHERE uuid = ?1',
        arguments: [uuid]);
  }

  @override
  Future<List<WalletAddress>> getAddressesByPersona(String uuid) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WalletAddress WHERE uuid = ?1',
        mapper: (Map<String, Object?> row) => WalletAddress(
            address: row['address'] as String,
            uuid: row['uuid'] as String,
            index: row['index'] as int,
            cryptoType: row['cryptoType'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            isHidden: (row['isHidden'] as int) != 0,
            name: row['name'] as String?,
            accountOrder: row['accountOrder'] as int?),
        arguments: [uuid]);
  }

  @override
  Future<void> insertAddresses(List<WalletAddress> addresses) async {
    await _walletAddressInsertionAdapter.insertList(
        addresses, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateAddress(WalletAddress address) async {
    await _walletAddressUpdateAdapter.update(address, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteAddress(WalletAddress address) async {
    await _walletAddressDeletionAdapter.delete(address);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
