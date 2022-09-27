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

  PersonaDao? _personaDaoInstance;

  ConnectionDao? _connectionDaoInstance;

  AuditDao? _auditDaoInstance;

  Future<sqflite.Database> open(String path, List<Migration> migrations,
      [Callback? callback]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 3,
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
            'CREATE TABLE IF NOT EXISTS `Persona` (`uuid` TEXT NOT NULL, `name` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `defaultAccount` INTEGER, PRIMARY KEY (`uuid`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Connection` (`key` TEXT NOT NULL, `name` TEXT NOT NULL, `data` TEXT NOT NULL, `connectionType` TEXT NOT NULL, `accountNumber` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`key`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Audit` (`uuid` TEXT NOT NULL, `category` TEXT NOT NULL, `action` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `metadata` TEXT NOT NULL, PRIMARY KEY (`uuid`))');

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
}

class _$PersonaDao extends PersonaDao {
  _$PersonaDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _personaInsertionAdapter = InsertionAdapter(
            database,
            'Persona',
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount
                }),
        _personaUpdateAdapter = UpdateAdapter(
            database,
            'Persona',
            ['uuid'],
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount
                }),
        _personaDeletionAdapter = DeletionAdapter(
            database,
            'Persona',
            ['uuid'],
            (Persona item) => <String, Object?>{
                  'uuid': item.uuid,
                  'name': item.name,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'defaultAccount': item.defaultAccount
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
            defaultAccount: row['defaultAccount'] as int?));
  }

  @override
  Future<List<Persona>> getDefaultPersonas() async {
    return _queryAdapter.queryList(
        'SELECT * FROM Persona WHERE defaultAccount=1',
        mapper: (Map<String, Object?> row) => Persona(
            uuid: row['uuid'] as String,
            name: row['name'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            defaultAccount: row['defaultAccount'] as int?));
  }

  @override
  Future<void> setUniqueDefaultAccount(String uuid) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE Persona SET defaultAccount = 1 WHERE uuid = ?1; UPDATE Persona SET defaultAccount = 0 WHERE uuid != ?1;',
        arguments: [uuid]);
  }

  @override
  Future<int?> getPersonasCount() async {
    await _queryAdapter.queryNoReturn('SELECT COUNT(*) FROM Persona');
  }

  @override
  Future<Persona?> findById(String uuid) async {
    return _queryAdapter.query('SELECT * FROM Persona WHERE uuid = ?1',
        mapper: (Map<String, Object?> row) => Persona(
            uuid: row['uuid'] as String,
            name: row['name'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            defaultAccount: row['defaultAccount'] as int?),
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
  Future<void> updatePersona(Persona persona) async {
    await _personaUpdateAdapter.update(persona, OnConflictStrategy.abort);
  }

  @override
  Future<void> deletePersona(Persona persona) async {
    await _personaDeletionAdapter.delete(persona);
  }
}

class _$ConnectionDao extends ConnectionDao {
  _$ConnectionDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
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
        'SELECT * FROM Connection WHERE connectionType NOT IN (\"dappConnect\", \"beaconP2PPeer\", \"manuallyIndexerTokenID\")',
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
        'SELECT * FROM Connection WHERE connectionType IN (\"dappConnect\", \"beaconP2PPeer\")',
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
        'SELECT * FROM Connection WHERE connectionType = ?1',
        mapper: (Map<String, Object?> row) => Connection(
            key: row['key'] as String,
            name: row['name'] as String,
            data: row['data'] as String,
            connectionType: row['connectionType'] as String,
            accountNumber: row['accountNumber'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int)),
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
}

class _$AuditDao extends AuditDao {
  _$AuditDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
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
  Future<List<Audit>> getAuditsBy(String category, String action) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Audit WHERE category = (?1) AND action = (?2)',
        mapper: (Map<String, Object?> row) => Audit(
            uuid: row['uuid'] as String,
            category: row['category'] as String,
            action: row['action'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            metadata: row['metadata'] as String),
        arguments: [category, action]);
  }

  @override
  Future<List<Audit>> getAuditsByCategoryActions(
      List<String> fullAccountActions,
      List<String> socialRecoveryActions) async {
    int offset = 1;
    final _sqliteVariablesForFullAccountActions = Iterable<String>.generate(
        fullAccountActions.length, (i) => '?${i + offset}').join(',');
    offset += fullAccountActions.length;
    final _sqliteVariablesForSocialRecoveryActions = Iterable<String>.generate(
        socialRecoveryActions.length, (i) => '?${i + offset}').join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM Audit WHERE (category = \'fullAccount\' AND action IN (' +
            _sqliteVariablesForFullAccountActions +
            '))     OR (category = \'socialRecovery\' AND action IN (' +
            _sqliteVariablesForSocialRecoveryActions +
            ')) ORDER BY createdAt DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => Audit(uuid: row['uuid'] as String, category: row['category'] as String, action: row['action'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), metadata: row['metadata'] as String),
        arguments: [...fullAccountActions, ...socialRecoveryActions]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Audit');
  }

  @override
  Future<void> insertAudit(Audit audit) async {
    await _auditInsertionAdapter.insert(audit, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
