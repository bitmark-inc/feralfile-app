//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/dao/announcement_dao.dart';
import 'package:autonomy_flutter/database/dao/draft_customer_support_dao.dart';
import 'package:autonomy_flutter/database/dao/identity_dao.dart';
import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:floor/floor.dart';
import 'package:nft_collection/models/token.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

//ignore_for_file: lines_longer_than_80_chars

part 'app_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter, TokenOwnersConverter])
@Database(version: 18, entities: [
  Identity,
  DraftCustomerSupport,
  AnnouncementLocal,
  Scene,
])
abstract class AppDatabase extends FloorDatabase {
  IdentityDao get identityDao;

  DraftCustomerSupportDao get draftCustomerSupportDao;

  AnnouncementLocalDao get announcementDao;

  Future<dynamic> removeAll() async {
    await identityDao.removeAll();
    await draftCustomerSupportDao.removeAll();
    await announcementDao.removeAll();
  }
}

final migrateV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
      'ALTER TABLE AssetToken ADD COLUMN lastActivityTime int DEFAULT(0)');
  log.info('Migrated App database from version 1 to 2');
});

final migrateV2ToV3 = Migration(2, 3, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`txID`))');
  log.info('Migrated App database from version 2 to 3');
});

// For unknown reason, execute DROP then CREATE in same migration execution doesn't work.
// So I have to separate 2 versions
final migrateV3ToV4 = Migration(3, 4, (database) async {
  await database.execute('DROP TABLE IF EXISTS Provenance;');
  log.info('Migrated App database from version 3 to 4');
});

final migrateV4ToV5 = Migration(4, 5, (database) async {
  await database.execute('''
      CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `txURL` TEXT NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`txID`));
      CREATE INDEX `index_Provenance_tokenID` ON `Provenance` (`tokenID`);''');
  log.info('Migrated App database from version 4 to 5');
});

final migrateV5ToV6 = Migration(5, 6, (database) async {
  await database
      .execute('ALTER TABLE AssetToken ADD COLUMN hidden int DEFAULT(NULL)');
  log.info('Migrated App database from version 5 to 6');
});

final migrateV6ToV7 = Migration(6, 7, (database) async {
  await database.execute('''
    DROP TABLE IF EXISTS Provenance;
  ''');
  log.info('Migrated App database from version 6 to 7');
});

final migrateV7ToV8 = Migration(7, 8, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `txURL` TEXT NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE, PRIMARY KEY (`txID`));
    CREATE INDEX `index_Provenance_tokenID` ON `Provenance` (`tokenID`);
  ''');
  log.info('Migrated App database from version 7 to 8');
});

final migrateV8ToV9 = Migration(8, 9, (database) async {
  await database.execute('''
    ALTER TABLE AssetToken ADD COLUMN blockchainURL TEXT;
  ''');
  log.info('Migrated App database from version 8 to 9');
});

final migrateV9ToV10 = Migration(9, 10, (database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `DraftCustomerSupport` (`uuid` TEXT NOT NULL, `issueID` TEXT NOT NULL, `type` TEXT NOT NULL, `data` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `reportIssueType` TEXT NOT NULL, `mutedMessages` TEXT NOT NULL, PRIMARY KEY (`uuid`));
  ''');
  log.info('Migrated App database from version 9 to 10');
});

final migrateV10ToV11 = Migration(10, 11, (database) async {
  await database.execute('''
    ALTER TABLE AssetToken ADD COLUMN mimeType TEXT;
  ''');
  log.info('Migrated App database from version 10 to 11');
});

final migrateV11ToV12 = Migration(11, 12, (database) async {
  await database.execute('''
    ALTER TABLE AssetToken ADD COLUMN artistID TEXT;
  ''');
  log.info('Migrated App database from version 11 to 12');
});

final migrateV12ToV13 = Migration(12, 13, (database) async {
  await database.execute('''
    ALTER TABLE AssetToken ADD COLUMN contractAddress TEXT, tokenId TEXT;
  ''');
  log.info('Migrated App database from version 12 to 13');
});

final migrateV13ToV14 = Migration(13, 14, (database) async {
  await database.execute('DROP TABLE IF EXISTS AssetToken;');
  await database.execute('DROP TABLE IF EXISTS Provenance;');
  log.info('Migrated App database from version 13 to 14');
});

final migrateV14ToV15 = Migration(14, 15, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `AnnouncementLocal` (`announcementContextId` TEXT NOT NULL, `title` TEXT NOT NULL, `body` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `announceAt` INTEGER NOT NULL, `type` TEXT NOT NULL, `unread` INTEGER NOT NULL,  PRIMARY KEY (`announcementContextId`))');
  log.info('Migrated App database from version 14 to 15');
});

final migrateV15ToV16 = Migration(15, 16, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `CanvasDevice` (`id` TEXT NOT NULL, `ip` TEXT NOT NULL, `port` INTEGER NOT NULL, `name` TEXT NOT NULL, `isConnecting` INTEGER NOT NULL, `lastScenePlayed` TEXT, `playingSceneId` TEXT,  PRIMARY KEY (`id`))');
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Scene` (`id` TEXT NOT NULL, `deviceId` TEXT NOT NULL, `metadata` TEXT NOT NULL, PRIMARY KEY (`id`))');
  log.info('Migrated App database from version 15 to 16');
});

final migrateV16ToV17 = Migration(16, 17, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Followee` (`address` TEXT NOT NULL, `type` INTEGER NOT NULL, `isFollowed` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, `name` TEXT NOT NULL, PRIMARY KEY (`address`))');
  log.info('Migrated from version 16 to 17');
});

final migrateV17ToV18 = Migration(17, 18, (database) async {
  await database.execute('DROP TABLE IF EXISTS Followee;');
  log.info('Migrated App database from version 17 to 18');
});

final migrateV18ToV19 = Migration(18, 19, (database) async {
  await database.execute('DROP TABLE IF EXISTS CanvasDevice;');
  await database.execute('DROP TABLE IF EXISTS Scene;');
  log.info('Migrated App database from version 18 to 18');
});
