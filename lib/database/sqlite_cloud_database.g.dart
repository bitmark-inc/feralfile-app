// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sqlite_cloud_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorSqliteCloudDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$SqliteCloudDatabaseBuilder databaseBuilder(String name) =>
      _$SqliteCloudDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$SqliteCloudDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$SqliteCloudDatabaseBuilder(null);
}

class _$SqliteCloudDatabaseBuilder {
  _$SqliteCloudDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$SqliteCloudDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$SqliteCloudDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<SqliteCloudDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$SqliteCloudDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$SqliteCloudDatabase extends SqliteCloudDatabase {
  _$SqliteCloudDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  PersonaDao? _personaDaoInstance;

  ConnectionDao? _connectionDaoInstance;

  AuditDao? _auditDaoInstance;

  WalletAddressDao? _addressDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 8,
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
            'CREATE TABLE IF NOT EXISTS `Persona` (`uuid` TEXT NOT NULL, `name` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `defaultAccount` INTEGER, `ethereumIndex` INTEGER NOT NULL, `tezosIndex` INTEGER NOT NULL, `ethereumIndexes` TEXT, `tezosIndexes` TEXT, PRIMARY KEY (`uuid`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Connection` (`key` TEXT NOT NULL, `name` TEXT NOT NULL, `data` TEXT NOT NULL, `connectionType` TEXT NOT NULL, `accountNumber` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Audit` (`uuid` TEXT NOT NULL, `category` TEXT NOT NULL, `action` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `metadata` TEXT NOT NULL, PRIMARY KEY (`uuid`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WalletAddress` (`address` TEXT NOT NULL, `uuid` TEXT NOT NULL, `index` INTEGER NOT NULL, `cryptoType` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `isHidden` INTEGER NOT NULL, `name` TEXT, PRIMARY KEY (`address`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  PersonaDao get personaDao {
    return _personaDaoInstance ??= _$PersonaDao(database, changeListener);
  }

  @override
  ConnectionDao get connectionDao {
    return _connectionDaoInstance ??= _$ConnectionDao(database, changeListener);
  }

  @override
  AuditDao get auditDao {
    return _auditDaoInstance ??= _$AuditDao(database, changeListener);
  }

  @override
  WalletAddressDao get addressDao {
    return _addressDaoInstance ??= _$WalletAddressDao(database, changeListener);
  }
}

class _$PersonaDao extends PersonaDao {
  _$PersonaDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _personaInsertionAdapter = InsertionAdapter(
            database,
            'Persona',
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount,
                  'ethereumIndex': item.ethereumIndex,
                  'tezosIndex': item.tezosIndex,
                  'ethereumIndexes': item.ethereumIndexes,
                  'tezosIndexes': item.tezosIndexes
                }),
        _personaUpdateAdapter = UpdateAdapter(
            database,
            'Persona',
            ['uuid'],
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount,
                  'ethereumIndex': item.ethereumIndex,
                  'tezosIndex': item.tezosIndex,
                  'ethereumIndexes': item.ethereumIndexes,
                  'tezosIndexes': item.tezosIndexes
                }),
        _personaDeletionAdapter = DeletionAdapter(
            database,
            'Persona',
            ['uuid'],
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount,
                  'ethereumIndex': item.ethereumIndex,
                  'tezosIndex': item.tezosIndex,
                  'ethereumIndexes': item.ethereumIndexes,
                  'tezosIndexes': item.tezosIndexes
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Persona> _personaInsertionAdapter;

  final UpdateAdapter<Persona> _personaUpdateAdapter;

  final DeletionAdapter<Persona> _personaDeletionAdapter;

  @override
  Future<List<Persona>> getPersonas() async {
    return _queryAdapter.queryList('SELECT * FROM Persona',
        mapper: (Map<String, Object?> row) => Persona(
            uuid: row['uuid'] as String,
            name: row['name'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            defaultAccount: row['defaultAccount'] as int?,
            ethereumIndex: row['ethereumIndex'] as int,
            tezosIndex: row['tezosIndex'] as int,
            ethereumIndexes: row['ethereumIndexes'] as String?,
            tezosIndexes: row['tezosIndexes'] as String?));
  }

  @override
  Future<List<Persona>> getDefaultPersonas() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Persona WHERE defaultAccount=1',
        mapper: (Map<String, Object?> row) => Persona(
            uuid: row['uuid'] as String,
            name: row['name'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            defaultAccount: row['defaultAccount'] as int?,
            ethereumIndex: row['ethereumIndex'] as int,
            tezosIndex: row['tezosIndex'] as int,
            ethereumIndexes: row['ethereumIndexes'] as String?,
            tezosIndexes: row['tezosIndexes'] as String?));
  }

  @override
  Future<int?> getPersonasCount() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM Persona',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<Persona?> findById(String uuid) async {
    return _queryAdapter.query('SELECT * FROM Persona WHERE uuid = ?1',
        mapper: (Map<String, Object?> row) => Persona(
            uuid: row['uuid'] as String,
            name: row['name'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            defaultAccount: row['defaultAccount'] as int?,
            ethereumIndex: row['ethereumIndex'] as int,
            tezosIndex: row['tezosIndex'] as int,
            ethereumIndexes: row['ethereumIndexes'] as String?,
            tezosIndexes: row['tezosIndexes'] as String?),
        arguments: [uuid]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Persona');
  }

  @override
  Future<void> insertPersona(Persona persona) async {
    await _personaInsertionAdapter.insert(persona, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertPersonas(List<Persona> personas) async {
    await _personaInsertionAdapter.insertList(
        personas, OnConflictStrategy.replace);
  }

  @override
  Future<void> updatePersona(Persona persona) async {
    await _personaUpdateAdapter.update(persona, OnConflictStrategy.abort);
  }

  @override
  Future<void> deletePersona(Persona persona) async {
    await _personaDeletionAdapter.delete(persona);
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
                  'createdAt': _dateTimeConverter.encode(item.createdAt)
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
                  'createdAt': _dateTimeConverter.encode(item.createdAt)
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
                  'createdAt': _dateTimeConverter.encode(item.createdAt)
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
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)));
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
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)));
  }

  @override
  Future<List<Connection>> getRelatedPersonaConnections() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE connectionType IN (\"dappConnect\", \"dappConnect2\", \"beaconP2PPeer\")',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)));
  }

  @override
  Future<List<Connection>> getConnectionsByType(String type) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Connection WHERE connectionType = ?1 ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => Connection(key: row['key'] as String, name: row['name'] as String, data: row['data'] as String, connectionType: row['connectionType'] as String, accountNumber: row['accountNumber'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int)),
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
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [accountNumber]);
  }

  @override
  Future<Connection?> findById(String key) async {
    return _queryAdapter.query('SELECT * FROM Connection WHERE key = ?1',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [key]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Connection');
  }

  @override
  Future<void> deleteConnectionsByAccountNumber(String accountNumber) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Connection WHERE accountNumber = ?1 COLLATE NOCASE',
        arguments: [accountNumber]);
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

class _$AuditDao extends AuditDao {
  _$AuditDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _auditInsertionAdapter = InsertionAdapter(
            database,
            'Audit',
            (Audit item) => <String, Object?>{
                  'uuid': item.uuid,
                  'category': item.category,
                  'action': item.action,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'metadata': item.metadata
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Audit> _auditInsertionAdapter;

  @override
  Future<List<Audit>> getAudits() async {
    return _queryAdapter.queryList('SELECT * FROM Audit',
        mapper: (Map<String, Object?> row) => Audit(
            uuid: row['uuid'] as String,
            category: row['category'] as String,
            action: row['action'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            metadata: row['metadata'] as String));
  }

  @override
  Future<List<Audit>> getAuditsBy(
    String category,
    String action,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Audit WHERE category = (?1) AND \"action\" = (?2)',
        mapper: (Map<String, Object?> row) => Audit(
            uuid: row['uuid'] as String,
            category: row['category'] as String,
            action: row['action'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            metadata: row['metadata'] as String),
        arguments: [category, action]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Audit');
  }

  @override
  Future<void> insertAudit(Audit audit) async {
    await _auditInsertionAdapter.insert(audit, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertAudits(List<Audit> audits) async {
    await _auditInsertionAdapter.insertList(audits, OnConflictStrategy.replace);
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
                  'name': item.name
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
                  'name': item.name
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
                  'name': item.name
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
            name: row['name'] as String?));
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
            name: row['name'] as String?),
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
            name: row['name'] as String?),
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
            name: row['name'] as String?),
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
            name: row['name'] as String?),
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
            name: row['name'] as String?),
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
  Future<void> insertAddress(WalletAddress address) async {
    await _walletAddressInsertionAdapter.insert(
        address, OnConflictStrategy.replace);
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
