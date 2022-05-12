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

  AssetTokenDao? _assetDaoInstance;

  IdentityDao? _identityDaoInstance;

  ProvenanceDao? _provenanceDaoInstance;

  DraftCustomerSupportDao? _draftCustomerSupportDaoInstance;

  Future<sqflite.Database> open(String path, List<Migration> migrations,
      [Callback? callback]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 10,
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
            'CREATE TABLE IF NOT EXISTS `AssetToken` (`artistName` TEXT, `artistURL` TEXT, `assetData` TEXT, `assetID` TEXT, `assetURL` TEXT, `basePrice` REAL, `baseCurrency` TEXT, `blockchain` TEXT NOT NULL, `contractType` TEXT, `blockchainURL` TEXT, `desc` TEXT, `edition` INTEGER NOT NULL, `id` TEXT NOT NULL, `maxEdition` INTEGER, `medium` TEXT, `mintedAt` TEXT, `previewURL` TEXT, `source` TEXT, `sourceURL` TEXT, `thumbnailURL` TEXT, `galleryThumbnailURL` TEXT, `title` TEXT NOT NULL, `ownerAddress` TEXT, `lastActivityTime` INTEGER NOT NULL, `hidden` INTEGER, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Identity` (`accountNumber` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `name` TEXT NOT NULL, `queriedAt` INTEGER NOT NULL, PRIMARY KEY (`accountNumber`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `txURL` TEXT NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE, PRIMARY KEY (`txID`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `DraftCustomerSupport` (`uuid` TEXT NOT NULL, `issueID` TEXT NOT NULL, `type` TEXT NOT NULL, `data` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `reportIssueType` TEXT NOT NULL, `mutedMessages` TEXT NOT NULL, PRIMARY KEY (`uuid`))');
        await database.execute(
            'CREATE INDEX `index_Provenance_tokenID` ON `Provenance` (`tokenID`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  AssetTokenDao get assetDao {
    return _assetDaoInstance ??= _$AssetTokenDao(database, changeListener);
  }

  @override
  IdentityDao get identityDao {
    return _identityDaoInstance ??= _$IdentityDao(database, changeListener);
  }

  @override
  ProvenanceDao get provenanceDao {
    return _provenanceDaoInstance ??= _$ProvenanceDao(database, changeListener);
  }

  @override
  DraftCustomerSupportDao get draftCustomerSupportDao {
    return _draftCustomerSupportDaoInstance ??=
        _$DraftCustomerSupportDao(database, changeListener);
  }
}

class _$AssetTokenDao extends AssetTokenDao {
  _$AssetTokenDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _assetTokenInsertionAdapter = InsertionAdapter(
            database,
            'AssetToken',
            (AssetToken item) => <String, Object?>{
                  'artistName': item.artistName,
                  'artistURL': item.artistURL,
                  'assetData': item.assetData,
                  'assetID': item.assetID,
                  'assetURL': item.assetURL,
                  'basePrice': item.basePrice,
                  'baseCurrency': item.baseCurrency,
                  'blockchain': item.blockchain,
                  'contractType': item.contractType,
                  'blockchainURL': item.blockchainURL,
                  'desc': item.desc,
                  'edition': item.edition,
                  'id': item.id,
                  'maxEdition': item.maxEdition,
                  'medium': item.medium,
                  'mintedAt': item.mintedAt,
                  'previewURL': item.previewURL,
                  'source': item.source,
                  'sourceURL': item.sourceURL,
                  'thumbnailURL': item.thumbnailURL,
                  'galleryThumbnailURL': item.galleryThumbnailURL,
                  'title': item.title,
                  'ownerAddress': item.ownerAddress,
                  'lastActivityTime':
                      _dateTimeConverter.encode(item.lastActivityTime),
                  'hidden': item.hidden
                }),
        _assetTokenUpdateAdapter = UpdateAdapter(
            database,
            'AssetToken',
            ['id'],
            (AssetToken item) => <String, Object?>{
                  'artistName': item.artistName,
                  'artistURL': item.artistURL,
                  'assetData': item.assetData,
                  'assetID': item.assetID,
                  'assetURL': item.assetURL,
                  'basePrice': item.basePrice,
                  'baseCurrency': item.baseCurrency,
                  'blockchain': item.blockchain,
                  'contractType': item.contractType,
                  'blockchainURL': item.blockchainURL,
                  'desc': item.desc,
                  'edition': item.edition,
                  'id': item.id,
                  'maxEdition': item.maxEdition,
                  'medium': item.medium,
                  'mintedAt': item.mintedAt,
                  'previewURL': item.previewURL,
                  'source': item.source,
                  'sourceURL': item.sourceURL,
                  'thumbnailURL': item.thumbnailURL,
                  'galleryThumbnailURL': item.galleryThumbnailURL,
                  'title': item.title,
                  'ownerAddress': item.ownerAddress,
                  'lastActivityTime':
                      _dateTimeConverter.encode(item.lastActivityTime),
                  'hidden': item.hidden
                }),
        _assetTokenDeletionAdapter = DeletionAdapter(
            database,
            'AssetToken',
            ['id'],
            (AssetToken item) => <String, Object?>{
                  'artistName': item.artistName,
                  'artistURL': item.artistURL,
                  'assetData': item.assetData,
                  'assetID': item.assetID,
                  'assetURL': item.assetURL,
                  'basePrice': item.basePrice,
                  'baseCurrency': item.baseCurrency,
                  'blockchain': item.blockchain,
                  'contractType': item.contractType,
                  'blockchainURL': item.blockchainURL,
                  'desc': item.desc,
                  'edition': item.edition,
                  'id': item.id,
                  'maxEdition': item.maxEdition,
                  'medium': item.medium,
                  'mintedAt': item.mintedAt,
                  'previewURL': item.previewURL,
                  'source': item.source,
                  'sourceURL': item.sourceURL,
                  'thumbnailURL': item.thumbnailURL,
                  'galleryThumbnailURL': item.galleryThumbnailURL,
                  'title': item.title,
                  'ownerAddress': item.ownerAddress,
                  'lastActivityTime':
                      _dateTimeConverter.encode(item.lastActivityTime),
                  'hidden': item.hidden
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AssetToken> _assetTokenInsertionAdapter;

  final UpdateAdapter<AssetToken> _assetTokenUpdateAdapter;

  final DeletionAdapter<AssetToken> _assetTokenDeletionAdapter;

  @override
  Future<List<AssetToken>> findAllAssetTokens() async {
    return _queryAdapter.queryList(
        'SELECT * FROM AssetToken ORDER BY lastActivityTime DESC, title, assetID',
        mapper: (Map<String, Object?> row) => AssetToken(
            artistName: row['artistName'] as String?,
            artistURL: row['artistURL'] as String?,
            assetData: row['assetData'] as String?,
            assetID: row['assetID'] as String?,
            assetURL: row['assetURL'] as String?,
            basePrice: row['basePrice'] as double?,
            baseCurrency: row['baseCurrency'] as String?,
            blockchain: row['blockchain'] as String,
            contractType: row['contractType'] as String?,
            blockchainURL: row['blockchainURL'] as String?,
            desc: row['desc'] as String?,
            edition: row['edition'] as int,
            id: row['id'] as String,
            maxEdition: row['maxEdition'] as int?,
            medium: row['medium'] as String?,
            mintedAt: row['mintedAt'] as String?,
            previewURL: row['previewURL'] as String?,
            source: row['source'] as String?,
            sourceURL: row['sourceURL'] as String?,
            thumbnailURL: row['thumbnailURL'] as String?,
            galleryThumbnailURL: row['galleryThumbnailURL'] as String?,
            title: row['title'] as String,
            ownerAddress: row['ownerAddress'] as String?,
            lastActivityTime:
                _dateTimeConverter.decode(row['lastActivityTime'] as int),
            hidden: row['hidden'] as int?));
  }

  @override
  Future<List<AssetToken>> findAllAssetTokensWhereNot(
      List<String> owners) async {
    const offset = 1;
    final _sqliteVariablesForOwners =
        Iterable<String>.generate(owners.length, (i) => '?${i + offset}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * FROM AssetToken WHERE ownerAddress NOT IN (' +
            _sqliteVariablesForOwners +
            ') AND hidden is NULL ORDER BY lastActivityTime DESC, title, assetID',
        mapper: (Map<String, Object?> row) => AssetToken(artistName: row['artistName'] as String?, artistURL: row['artistURL'] as String?, assetData: row['assetData'] as String?, assetID: row['assetID'] as String?, assetURL: row['assetURL'] as String?, basePrice: row['basePrice'] as double?, baseCurrency: row['baseCurrency'] as String?, blockchain: row['blockchain'] as String, contractType: row['contractType'] as String?, blockchainURL: row['blockchainURL'] as String?, desc: row['desc'] as String?, edition: row['edition'] as int, id: row['id'] as String, maxEdition: row['maxEdition'] as int?, medium: row['medium'] as String?, mintedAt: row['mintedAt'] as String?, previewURL: row['previewURL'] as String?, source: row['source'] as String?, sourceURL: row['sourceURL'] as String?, thumbnailURL: row['thumbnailURL'] as String?, galleryThumbnailURL: row['galleryThumbnailURL'] as String?, title: row['title'] as String, ownerAddress: row['ownerAddress'] as String?, lastActivityTime: _dateTimeConverter.decode(row['lastActivityTime'] as int), hidden: row['hidden'] as int?),
        arguments: [...owners]);
  }

  @override
  Future<List<AssetToken>> findAssetTokensByBlockchain(
      String blockchain) async {
    return _queryAdapter.queryList(
        'SELECT * FROM AssetToken WHERE blockchain = ?1 AND hidden is NULL',
        mapper: (Map<String, Object?> row) => AssetToken(
            artistName: row['artistName'] as String?,
            artistURL: row['artistURL'] as String?,
            assetData: row['assetData'] as String?,
            assetID: row['assetID'] as String?,
            assetURL: row['assetURL'] as String?,
            basePrice: row['basePrice'] as double?,
            baseCurrency: row['baseCurrency'] as String?,
            blockchain: row['blockchain'] as String,
            contractType: row['contractType'] as String?,
            blockchainURL: row['blockchainURL'] as String?,
            desc: row['desc'] as String?,
            edition: row['edition'] as int,
            id: row['id'] as String,
            maxEdition: row['maxEdition'] as int?,
            medium: row['medium'] as String?,
            mintedAt: row['mintedAt'] as String?,
            previewURL: row['previewURL'] as String?,
            source: row['source'] as String?,
            sourceURL: row['sourceURL'] as String?,
            thumbnailURL: row['thumbnailURL'] as String?,
            galleryThumbnailURL: row['galleryThumbnailURL'] as String?,
            title: row['title'] as String,
            ownerAddress: row['ownerAddress'] as String?,
            lastActivityTime:
                _dateTimeConverter.decode(row['lastActivityTime'] as int),
            hidden: row['hidden'] as int?),
        arguments: [blockchain]);
  }

  @override
  Future<AssetToken?> findAssetTokenById(String id) async {
    return _queryAdapter.query('SELECT * FROM AssetToken WHERE id = ?1',
        mapper: (Map<String, Object?> row) => AssetToken(
            artistName: row['artistName'] as String?,
            artistURL: row['artistURL'] as String?,
            assetData: row['assetData'] as String?,
            assetID: row['assetID'] as String?,
            assetURL: row['assetURL'] as String?,
            basePrice: row['basePrice'] as double?,
            baseCurrency: row['baseCurrency'] as String?,
            blockchain: row['blockchain'] as String,
            contractType: row['contractType'] as String?,
            blockchainURL: row['blockchainURL'] as String?,
            desc: row['desc'] as String?,
            edition: row['edition'] as int,
            id: row['id'] as String,
            maxEdition: row['maxEdition'] as int?,
            medium: row['medium'] as String?,
            mintedAt: row['mintedAt'] as String?,
            previewURL: row['previewURL'] as String?,
            source: row['source'] as String?,
            sourceURL: row['sourceURL'] as String?,
            thumbnailURL: row['thumbnailURL'] as String?,
            galleryThumbnailURL: row['galleryThumbnailURL'] as String?,
            title: row['title'] as String,
            ownerAddress: row['ownerAddress'] as String?,
            lastActivityTime:
                _dateTimeConverter.decode(row['lastActivityTime'] as int),
            hidden: row['hidden'] as int?),
        arguments: [id]);
  }

  @override
  Future<List<String>> findAllAssetTokenIDs() async {
    return _queryAdapter.queryList('SELECT id FROM AssetToken',
        mapper: (Map<String, Object?> row) => row['id'] as String);
  }

  @override
  Future<List<AssetToken>> findAllHiddenAssets() async {
    return _queryAdapter.queryList('SELECT * FROM AssetToken WHERE hidden = 1',
        mapper: (Map<String, Object?> row) => AssetToken(
            artistName: row['artistName'] as String?,
            artistURL: row['artistURL'] as String?,
            assetData: row['assetData'] as String?,
            assetID: row['assetID'] as String?,
            assetURL: row['assetURL'] as String?,
            basePrice: row['basePrice'] as double?,
            baseCurrency: row['baseCurrency'] as String?,
            blockchain: row['blockchain'] as String,
            contractType: row['contractType'] as String?,
            blockchainURL: row['blockchainURL'] as String?,
            desc: row['desc'] as String?,
            edition: row['edition'] as int,
            id: row['id'] as String,
            maxEdition: row['maxEdition'] as int?,
            medium: row['medium'] as String?,
            mintedAt: row['mintedAt'] as String?,
            previewURL: row['previewURL'] as String?,
            source: row['source'] as String?,
            sourceURL: row['sourceURL'] as String?,
            thumbnailURL: row['thumbnailURL'] as String?,
            galleryThumbnailURL: row['galleryThumbnailURL'] as String?,
            title: row['title'] as String,
            ownerAddress: row['ownerAddress'] as String?,
            lastActivityTime:
                _dateTimeConverter.decode(row['lastActivityTime'] as int),
            hidden: row['hidden'] as int?));
  }

  @override
  Future<int?> findNumOfHiddenAssets() async {
    return _queryAdapter.query(
        'SELECT COUNT(*) FROM AssetToken WHERE hidden = 1',
        mapper: (Map<String, Object?> row) => row['COUNT(*)'] as int);
  }

  @override
  Future<void> updateHiddenAssets(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'UPDATE AssetToken SET hidden = 1 WHERE id IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteAssetsNotIn(List<String> ids) async {
    const offset = 1;
    final _sqliteVariablesForIds =
        Iterable<String>.generate(ids.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM AssetToken WHERE id NOT IN (' +
            _sqliteVariablesForIds +
            ')',
        arguments: [...ids]);
  }

  @override
  Future<void> deleteAssetsNotBelongs(List<String> owners) async {
    const offset = 1;
    final _sqliteVariablesForOwners =
        Iterable<String>.generate(owners.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM AssetToken WHERE ownerAddress NOT IN (' +
            _sqliteVariablesForOwners +
            ')',
        arguments: [...owners]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM AssetToken');
  }

  @override
  Future<void> insertAsset(AssetToken asset) async {
    await _assetTokenInsertionAdapter.insert(asset, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertAssets(List<AssetToken> assets) async {
    await _assetTokenInsertionAdapter.insertList(
        assets, OnConflictStrategy.replace);
  }

  @override
  Future<void> updateAsset(AssetToken asset) async {
    await _assetTokenUpdateAdapter.update(asset, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteAsset(AssetToken asset) async {
    await _assetTokenDeletionAdapter.delete(asset);
  }
}

class _$IdentityDao extends IdentityDao {
  _$IdentityDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
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

class _$ProvenanceDao extends ProvenanceDao {
  _$ProvenanceDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _provenanceInsertionAdapter = InsertionAdapter(
            database,
            'Provenance',
            (Provenance item) => <String, Object?>{
                  'txID': item.txID,
                  'type': item.type,
                  'blockchain': item.blockchain,
                  'owner': item.owner,
                  'timestamp': _dateTimeConverter.encode(item.timestamp),
                  'txURL': item.txURL,
                  'tokenID': item.tokenID
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Provenance> _provenanceInsertionAdapter;

  @override
  Future<List<Provenance>> findProvenanceByTokenID(String tokenID) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Provenance WHERE tokenID = ?1',
        mapper: (Map<String, Object?> row) => Provenance(
            type: row['type'] as String,
            blockchain: row['blockchain'] as String,
            txID: row['txID'] as String,
            owner: row['owner'] as String,
            timestamp: _dateTimeConverter.decode(row['timestamp'] as int),
            txURL: row['txURL'] as String,
            tokenID: row['tokenID'] as String),
        arguments: [tokenID]);
  }

  @override
  Future<void> deleteProvenanceNotBelongs(List<String> tokenIDs) async {
    const offset = 1;
    final _sqliteVariablesForTokenIDs =
        Iterable<String>.generate(tokenIDs.length, (i) => '?${i + offset}')
            .join(',');
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Provenance WHERE tokenID NOT IN (' +
            _sqliteVariablesForTokenIDs +
            ')',
        arguments: [...tokenIDs]);
  }

  @override
  Future<void> removeAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM Provenance');
  }

  @override
  Future<void> insertProvenance(List<Provenance> provenance) async {
    await _provenanceInsertionAdapter.insertList(
        provenance, OnConflictStrategy.replace);
  }
}

class _$DraftCustomerSupportDao extends DraftCustomerSupportDao {
  _$DraftCustomerSupportDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
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
  Future<void> updateIssueID(String oldIssueID, String newIssueID) async {
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
