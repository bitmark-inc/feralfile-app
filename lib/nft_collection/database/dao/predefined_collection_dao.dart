//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:autonomy_flutter/nft_collection/models/predefined_collection_model.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

abstract class PredefinedCollectionDao {
  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByArtist(
      {String name = ""});

  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByMedium(
      {String title = "",
      required List<String> mimeTypes,
      required List<String> mediums,
      bool isInMimeTypes = true});
}

@dao
class PredefinedCollectionDaoImpl implements PredefinedCollectionDao {
  PredefinedCollectionDaoImpl(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  static PredefinedCollectionModel Function(Map<String, Object?>) mapper =
      (Map<String, Object?> row) {
    return PredefinedCollectionModel(
      id: row['id'] as String? ?? '',
      name: row['name'] as String?,
      total: row['total'] as int? ?? 0,
      thumbnailURL: row['thumbnailURL'] as String?,
    );
  };

  final QueryAdapter _queryAdapter;

  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByArtist(
      {String name = ""}) async {
    final nameFilter = "%${name.toLowerCase()}%";
    return _queryAdapter.queryList(
      'SELECT count(Token.id) as total, artistID as id, artistName as name, Asset.galleryThumbnailURL as  thumbnailURL FROM Token LEFT JOIN Asset  ON Token.indexID = Asset.indexID JOIN AddressCollection ON Token.owner = AddressCollection.address WHERE LOWER(name) LIKE ?1 AND AddressCollection.isHidden = 0 AND balance > 0 GROUP BY artistID ORDER BY total DESC',
      mapper: mapper,
      arguments: [nameFilter],
    );
  }

  Future<List<PredefinedCollectionModel>> getPredefinedCollectionsByMedium(
      {String title = "",
      required List<String> mimeTypes,
      required List<String> mediums,
      bool isInMimeTypes = true}) async {
    final titleFilter = "%${title.toLowerCase()}%";
    const offset = 3;
    final sqliteVariables =
        Iterable<String>.generate(mimeTypes.length, (i) => '?${i + offset}')
            .join(',');
    final mediumOffset = mimeTypes.length + offset;
    final sqliteVariablesForMedium =
        Iterable<String>.generate(mediums.length, (i) => '?${i + mediumOffset}')
            .join(',');
    final String inOrNotIn = isInMimeTypes ? '' : 'NOT';
    final id = mimeTypes.join(',');
    return _queryAdapter.queryList(
      'SELECT count(Token.id) as total, ?2 as id, ?2 as name, Asset.galleryThumbnailURL as  thumbnailURL FROM Token LEFT JOIN Asset  ON Token.indexID = Asset.indexID JOIN AddressCollection ON Token.owner = AddressCollection.address WHERE LOWER(Asset.title) LIKE ?1 AND AddressCollection.isHidden = 0 AND balance > 0 AND $inOrNotIn (mimeType IN ($sqliteVariables) OR medium IN ($sqliteVariablesForMedium))',
      mapper: mapper,
      arguments: [
        titleFilter,
        id,
        ...mimeTypes,
        ...mediums,
      ],
    );
  }
}
