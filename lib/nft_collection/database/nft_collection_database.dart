//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/nft_collection/database/dao/address_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/predefined_collection_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/nft_collection/database/dao/token_dao.dart';
import 'package:autonomy_flutter/nft_collection/models/address_collection.dart';
import 'package:autonomy_flutter/nft_collection/models/asset.dart';
import 'package:autonomy_flutter/nft_collection/models/provenance.dart';
import 'package:autonomy_flutter/nft_collection/models/token.dart';
import 'package:autonomy_flutter/nft_collection/utils/date_time_converter.dart';
import 'package:floor/floor.dart'; // ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart' as sqflite;

part 'nft_collection_database.g.dart'; // the generated code will be there

@TypeConverters([
  DateTimeConverter,
  NullableDateTimeConverter,
  TokenOwnersConverter,
])
@Database(version: 6, entities: [Token, Asset, Provenance, AddressCollection])
abstract class NftCollectionDatabase extends FloorDatabase {
  TokenDao get tokenDao;

  AssetTokenDao get assetTokenDao =>
      DatabaseAssetTokenDao(database, changeListener);

  PredefinedCollectionDao get predefinedCollectionDao =>
      PredefinedCollectionDaoImpl(database, changeListener);

  AssetDao get assetDao;

  ProvenanceDao get provenanceDao;

  AddressCollectionDao get addressCollectionDao;

  Future<dynamic> removeAll() async {
    await provenanceDao.removeAll();
    await tokenDao.removeAll();
    await assetDao.removeAll();
    await addressCollectionDao.removeAll();
  }
}

final migrations = <Migration>[
  migrateV1ToV2,
  migrateV2ToV3,
  migrateV3ToV4,
  migrateV4ToV5,
];

final migrateV1ToV2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE Asset ADD COLUMN artworkMetadata TEXT');
});

final migrateV2ToV3 = Migration(2, 3, (database) async {
  await database.execute('ALTER TABLE Asset ADD COLUMN artists TEXT');
});

final migrateV3ToV4 = Migration(3, 4, (database) async {
  final countBlockNumber = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Provenance') WHERE name='blockNumber';"));
  if (countBlockNumber == 0) {
    await database
        .execute('ALTER TABLE Provenance ADD COLUMN blockNumber INTEGER');
  }
});

final migrateV4ToV5 = Migration(4, 5, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `AddressCollection` (`address` TEXT NOT NULL, `lastRefreshedTime` INTEGER NOT NULL, `isHidden` INTEGER NOT NULL, PRIMARY KEY (`address`))');
});
