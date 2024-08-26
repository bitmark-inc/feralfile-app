// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$AppDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  /// Adds migrations to the builder.
  _$AppDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$AppDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  IdentityDao? _identityDaoInstance;

  DraftCustomerSupportDao? _draftCustomerSupportDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 20,
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
            'CREATE TABLE IF NOT EXISTS `Identity` (`accountNumber` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `name` TEXT NOT NULL, `queriedAt` INTEGER NOT NULL, PRIMARY KEY (`accountNumber`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `DraftCustomerSupport` (`uuid` TEXT NOT NULL, `issueID` TEXT NOT NULL, `type` TEXT NOT NULL, `data` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `reportIssueType` TEXT NOT NULL, `mutedMessages` TEXT NOT NULL, PRIMARY KEY (`uuid`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  IdentityDao get identityDao {
    return _identityDaoInstance ??= _$IdentityDao(database, changeListener);
  }

  @override
  DraftCustomerSupportDao get draftCustomerSupportDao {
    return _draftCustomerSupportDaoInstance ??=
        _$DraftCustomerSupportDao(database, changeListener);
  }
}

class _$IdentityDao extends IdentityDao {
  _$IdentityDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _identityInsertionAdapter = InsertionAdapter(
            database,
            'Identity',
            (Identity item) => <String, Object?>{
                  'accountNumber': item.accountNumber,
                  'blockchain': item.blockchain,
                  'name': item.name,
                  'queriedAt': _dateTimeConverter.encode(item.queriedAt)
                }),
        _identityUpdateAdapter = UpdateAdapter(
            database,
            'Identity',
            ['accountNumber'],
            (Identity item) => <String, Object?>{
                  'accountNumber': item.accountNumber,
                  'blockchain': item.blockchain,
                  'name': item.name,
                  'queriedAt': _dateTimeConverter.encode(item.queriedAt)
                }),
        _identityDeletionAdapter = DeletionAdapter(
            database,
            'Identity',
            ['accountNumber'],
            (Identity item) => <String, Object?>{
                  'accountNumber': item.accountNumber,
                  'blockchain': item.blockchain,
                  'name': item.name,
                  'queriedAt': _dateTimeConverter.encode(item.queriedAt)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Identity> _identityInsertionAdapter;

  final UpdateAdapter<Identity> _identityUpdateAdapter;

  final DeletionAdapter<Identity> _identityDeletionAdapter;

  @override
  Future<List<Identity>> getIdentities() async {
    return _queryAdapter.queryList('SELECT * FROM Identity',
        mapper: (Map<String, Object?> row) => Identity(
            row['accountNumber'] as String,
            row['blockchain'] as String,
            row['name'] as String));
  }

  @override
  Future<Identity?> findByAccountNumber(String accountNumber) async {
    return _queryAdapter.query(
        'SELECT * FROM Identity WHERE accountNumber = ?1',
        mapper: (Map<String, Object?> row) => Identity(
            row['accountNumber'] as String,
            row['blockchain'] as String,
            row['name'] as String),
        arguments: [accountNumber]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Identity');
  }

  @override
  Future<void> insertIdentity(Identity identity) async {
    await _identityInsertionAdapter.insert(
        identity, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateIdentity(Identity identity) async {
    await _identityUpdateAdapter.update(identity, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteIdentity(Identity identity) async {
    await _identityDeletionAdapter.delete(identity);
  }
}

class _$DraftCustomerSupportDao extends DraftCustomerSupportDao {
  _$DraftCustomerSupportDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _draftCustomerSupportInsertionAdapter = InsertionAdapter(
            database,
            'DraftCustomerSupport',
            (DraftCustomerSupport item) => <String, Object?>{
                  'uuid': item.uuid,
                  'issueID': item.issueID,
                  'type': item.type,
                  'data': item.data,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'reportIssueType': item.reportIssueType,
                  'mutedMessages': item.mutedMessages
                }),
        _draftCustomerSupportDeletionAdapter = DeletionAdapter(
            database,
            'DraftCustomerSupport',
            ['uuid'],
            (DraftCustomerSupport item) => <String, Object?>{
                  'uuid': item.uuid,
                  'issueID': item.issueID,
                  'type': item.type,
                  'data': item.data,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'reportIssueType': item.reportIssueType,
                  'mutedMessages': item.mutedMessages
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DraftCustomerSupport>
      _draftCustomerSupportInsertionAdapter;

  final DeletionAdapter<DraftCustomerSupport>
      _draftCustomerSupportDeletionAdapter;

  @override
  Future<List<DraftCustomerSupport>> fetchDrafts(int limit) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DraftCustomerSupport ORDER BY createdAt LIMIT ?1',
        mapper: (Map<String, Object?> row) => DraftCustomerSupport(
            uuid: row['uuid'] as String,
            issueID: row['issueID'] as String,
            type: row['type'] as String,
            data: row['data'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            reportIssueType: row['reportIssueType'] as String,
            mutedMessages: row['mutedMessages'] as String),
        arguments: [limit]);
  }

  @override
  Future<List<DraftCustomerSupport>> getDrafts(String issueID) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DraftCustomerSupport WHERE issueID = ?1 ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => DraftCustomerSupport(uuid: row['uuid'] as String, issueID: row['issueID'] as String, type: row['type'] as String, data: row['data'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), reportIssueType: row['reportIssueType'] as String, mutedMessages: row['mutedMessages'] as String),
        arguments: [issueID]);
  }

  @override
  Future<DraftCustomerSupport?> getDraft(String uuid) async {
    return _queryAdapter.query(
        'SELECT * FROM DraftCustomerSupport WHERE uuid = ?1',
        mapper: (Map<String, Object?> row) => DraftCustomerSupport(
            uuid: row['uuid'] as String,
            issueID: row['issueID'] as String,
            type: row['type'] as String,
            data: row['data'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            reportIssueType: row['reportIssueType'] as String,
            mutedMessages: row['mutedMessages'] as String),
        arguments: [uuid]);
  }

  @override
  Future<List<DraftCustomerSupport>> getAllDrafts() async {
    return _queryAdapter.queryList(
        'SELECT * FROM DraftCustomerSupport ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => DraftCustomerSupport(
            uuid: row['uuid'] as String,
            issueID: row['issueID'] as String,
            type: row['type'] as String,
            data: row['data'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            reportIssueType: row['reportIssueType'] as String,
            mutedMessages: row['mutedMessages'] as String));
  }

  @override
  Future<void> updateIssueID(
    String oldIssueID,
    String newIssueID,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE DraftCustomerSupport SET issueID = ?2 WHERE issueID = ?1',
        arguments: [oldIssueID, newIssueID]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM DraftCustomerSupport');
  }

  @override
  Future<void> insertDraft(DraftCustomerSupport draft) async {
    await _draftCustomerSupportInsertionAdapter.insert(
        draft, OnConflictStrategy.replace);
  }

  @override
  Future<void> deleteDraft(DraftCustomerSupport draft) async {
    await _draftCustomerSupportDeletionAdapter.delete(draft);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
final _tokenOwnersConverter = TokenOwnersConverter();
