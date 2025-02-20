//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:floor/floor.dart';
import 'package:autonomy_flutter/nft_collection/models/asset.dart';
import 'package:autonomy_flutter/nft_collection/models/asset_token.dart';
import 'package:autonomy_flutter/nft_collection/models/token.dart';
import 'package:autonomy_flutter/nft_collection/utils/date_time_converter.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
final _nullableDateTimeConverter = NullableDateTimeConverter();
final _tokenOwnersConverter = TokenOwnersConverter();

@dao
class AssetTokenDao {
  AssetTokenDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  static AssetToken
      Function(Map<String, Object?>) mapper = (Map<String, Object?>
          row) =>
      AssetToken(
        id: row['id'] as String,
        tokenId: row['tokenId'] as String?,
        blockchain: row['blockchain'] as String,
        fungible:
            row['fungible'] == null ? false : (row['fungible'] as int) != 0,
        contractType: row['contractType'] as String,
        contractAddress: row['contractAddress'] as String?,
        edition: row['edition'] as int,
        editionName: row['editionName'] as String?,
        mintedAt: _nullableDateTimeConverter.decode(row['mintedAt'] as int?),
        balance: row['balance'] as int?,
        owner: row['owner'] as String,
        owners: _tokenOwnersConverter.decode(row['owners'] as String),
        swapped: row['swapped'] == null ? null : (row['swapped'] as int) != 0,
        burned: row['burned'] == null ? null : (row['burned'] as int) != 0,
        pending: row['pending'] == null ? null : (row['pending'] as int) != 0,
        scrollable:
            row['scrollable'] == null ? null : (row['scrollable'] as int) != 0,
        lastActivityTime:
            _dateTimeConverter.decode(row['lastActivityTime'] as int),
        lastRefreshedTime:
            _dateTimeConverter.decode(row['tokenLastRefresh'] as int),
        ipfsPinned:
            row['ipfsPinned'] == null ? null : (row['ipfsPinned'] as int) != 0,
        isManual:
            row['isDebugged'] == null ? null : (row['isDebugged'] as int) != 0,
        originTokenInfo: [],
        provenance: [],
        originTokenInfoId: row['originTokenInfoId'] as String?,
        asset: Asset(
          row['indexID'] as String?,
          row['thumbnailID'] as String?,
          _nullableDateTimeConverter.decode(row['tokenLastRefresh'] as int?),
          row['artistID'] as String?,
          row['artistName'] as String?,
          row['artistURL'] as String?,
          row['artists'] as String?,
          row['assetID'] as String?,
          row['title'] as String?,
          row['description'] as String?,
          row['mimeType'] as String?,
          row['medium'] as String?,
          row['maxEdition'] as int?,
          row['source'] as String?,
          row['sourceURL'] as String?,
          row['previewURL'] as String?,
          row['thumbnailURL'] as String?,
          row['galleryThumbnailURL'] as String?,
          row['assetData'] as String?,
          row['assetURL'] as String?,
          row['initialSaleModel'] as String?,
          row['originalFileURL'] as String?,
          row['isFeralfileFrame'] == null
              ? null
              : (row['isFeralfileFrame'] as int) != 0,
          row['artworkMetadata'] as String?,
        ),
      );

  final QueryAdapter _queryAdapter;

  Future<List<AssetToken>> findAllAssetTokens() async {
    return _queryAdapter.queryList(
      'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID ORDER BY lastActivityTime DESC, id DESC',
      mapper: mapper,
    );
  }

  Future<List<AssetToken>> findAllAssetTokensByFilter({
    required String filter,
    bool withHidden = false,
  }) async {
    final titleFilter = "%$filter%";
    final artistFilter = "%$filter%";
    final withHiddenSql = withHidden ? '1' : 'AddressCollection.isHidden = 0';
    return _queryAdapter.queryList(
        "SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID JOIN AddressCollection ON Token.owner = AddressCollection.address WHERE (Asset.title LIKE ?1 OR Asset.artistName LIKE ?2)  AND $withHiddenSql ORDER BY lastActivityTime DESC, id DESC",
        mapper: mapper,
        arguments: [titleFilter, artistFilter]);
  }

  Future<List<AssetToken>> findAllAssetTokensWithoutOffset(
    List<String> owners,
  ) async {
    const offsetOwner = 1;
    final sqliteVariablesForOwner =
        Iterable<String>.generate(owners.length, (i) => '?${i + offsetOwner}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE owner IN ($sqliteVariablesForOwner) ORDER BY lastActivityTime DESC, id DESC',
        mapper: mapper,
        arguments: [...owners]);
  }

  Future<List<AssetToken>> findAllPendingAssetTokens() async {
    return _queryAdapter.queryList(
      'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE pending = 1',
      mapper: mapper,
    );
  }

  Future<DateTime?> getLastRefreshedTime() async {
    final listDateTime = await _queryAdapter.queryList(
        'SELECT lastRefreshedTime FROM Token ORDER BY lastRefreshedTime DESC LIMIT 1',
        mapper: (Map<String, Object?> row) =>
            _dateTimeConverter.decode(row.values.first as int));
    return listDateTime.isEmpty ? null : listDateTime.first;
  }

  Future<List<AssetToken>> findAllAssetTokensByOwners(
    List<String> owners,
    int limit,
    int lastTime,
    String id,
  ) async {
    const offsetOwner = 4;
    final sqliteVariablesForOwner =
        Iterable<String>.generate(owners.length, (i) => '?${i + offsetOwner}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE (owner IN ($sqliteVariablesForOwner)) AND balance > 0 AND (lastActivityTime < ?2 OR (lastActivityTime = ?2 AND id < ?3)) ORDER BY lastActivityTime DESC, id DESC LIMIT ?1',
        mapper: mapper,
        arguments: [limit, lastTime, id, ...owners]);
  }

  Future<List<AssetToken>> findAllAssetTokensBeforeByOwners(
    List<String> owners,
    int lastTime,
    String id,
  ) async {
    const offsetOwner = 3;
    final sqliteVariablesForOwner =
        Iterable<String>.generate(owners.length, (i) => '?${i + offsetOwner}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE (owner IN ($sqliteVariablesForOwner))  AND  (lastActivityTime >= ?1 AND id >= ?2) ORDER BY lastActivityTime DESC, id DESC LIMIT ?1',
        mapper: mapper,
        arguments: [lastTime, id, ...owners]);
  }

  Future<List<AssetToken>> findAllAssetTokensByOwnersAndContractAddress(
    List<String> owners,
    String contractAddress,
    int limit,
    int lastTime,
    String id,
  ) async {
    const offsetOwner = 4;
    final sqliteVariablesForOwner =
        Iterable<String>.generate(owners.length, (i) => '?${i + offsetOwner}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE (owner IN ($sqliteVariablesForOwner)) AND balance > 0 AND contractAddress = "$contractAddress" AND (lastActivityTime < ?2 OR (lastActivityTime = ?2 AND id < ?3)) ORDER BY lastActivityTime DESC, id DESC LIMIT ?1',
        mapper: mapper,
        arguments: [limit, lastTime, id, ...owners]);
  }

  Future<List<AssetToken>> findAllAssetTokensByArtistID({
    required String artistID,
    bool withHidden = false,
    String filter = "",
  }) {
    final withHiddenSql = withHidden ? '1' : 'AddressCollection.isHidden = 0';
    final titleFilter = "%${filter.toLowerCase()}%";
    return _queryAdapter.queryList(
      'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID JOIN AddressCollection ON Token.owner = AddressCollection.address WHERE artistID = "$artistID" AND $withHiddenSql AND balance > 0 AND LOWER(Asset.title) LIKE ?1 ORDER BY lastActivityTime DESC, id DESC',
      mapper: mapper,
      arguments: [titleFilter],
    );
  }

  Future<List<AssetToken>> findAllAssetTokensByMimeTypesOrMediums({
    required List<String> mimeTypes,
    required List<String> mediums,
    bool isInMimeTypes = true,
    bool withHidden = false,
    String filter = "",
  }) {
    const mimeTypeOffset = 2;
    final sqliteVariables = Iterable<String>.generate(
        mimeTypes.length, (i) => '?${i + mimeTypeOffset}').join(',');
    final mediumOffset = mimeTypes.length + mimeTypeOffset;
    final sqliteVariablesForMedium =
        Iterable<String>.generate(mediums.length, (i) => '?${i + mediumOffset}')
            .join(',');
    final String inOrNotIn = isInMimeTypes ? '' : 'NOT';
    final withHiddenSql = withHidden ? '1' : 'AddressCollection.isHidden = 0';
    final titleFilter = "%${filter.toLowerCase()}%";
    return _queryAdapter.queryList(
      'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID JOIN AddressCollection ON Token.owner = AddressCollection.address WHERE $inOrNotIn (mimeType IN ($sqliteVariables) OR medium IN ($sqliteVariablesForMedium)) AND $withHiddenSql AND LOWER(Asset.title) LIKE ?1 AND balance > 0 ORDER BY lastActivityTime DESC, id DESC',
      mapper: mapper,
      arguments: [
        titleFilter,
        ...mimeTypes,
        ...mediums,
      ],
    );
  }

  Future<List<AssetToken>> findAllAssetTokensByTokenIDs(
    List<String> ids,
  ) async {
    const offsetOwner = 1;
    final sqliteVariablesForOwner =
        Iterable<String>.generate(ids.length, (i) => '?${i + offsetOwner}')
            .join(',');
    return _queryAdapter.queryList(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE ((id IN ($sqliteVariablesForOwner)))',
        mapper: mapper,
        arguments: [...ids]);
  }

  Future<AssetToken?> findAssetTokenByIdAndOwner(
      String id, String owner) async {
    return _queryAdapter.query(
        'SELECT * , Asset.lastRefreshedTime as assetLastRefresh, Token.lastRefreshedTime as tokenLastRefresh FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE id = ?1 AND owner = ?2',
        mapper: mapper,
        arguments: [id, owner]);
  }

  Future<List<String>> findAllAssetTokenIDsByOwner(String owner) async {
    return _queryAdapter.queryList(
        'SELECT id FROM Token LEFT JOIN Asset ON Token.indexID = Asset.indexID WHERE owner=?1',
        mapper: (Map<String, Object?> row) => row.values.first as String,
        arguments: [owner]);
  }
}
