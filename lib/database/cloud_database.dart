//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/dao/address_dao.dart';
import 'package:autonomy_flutter/database/dao/connection_dao.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/database/entity/wallet_address.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'cloud_database.g.dart'; // the generated code will be there
//ignore_for_file: lines_longer_than_80_chars

@TypeConverters([DateTimeConverter])
@Database(version: 10, entities: [Connection, WalletAddress])
abstract class CloudDatabase extends FloorDatabase {
  ConnectionDao get connectionDao;

  WalletAddressDao get addressDao;

  Future<dynamic> removeAll() async {
    await connectionDao.removeAll();
    await addressDao.removeAll();
  }

  Future<void> copyDataFrom(CloudDatabase source) async {
    await source.connectionDao.getConnections().then((connections) async {
      await connectionDao.insertConnections(connections);
    });

    await source.addressDao.getAllAddresses().then((addresses) async {
      await addressDao.insertAddresses(addresses);
    });
  }
}

final migrateCloudV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Audit` (`uuid` TEXT NOT NULL, `category` TEXT NOT NULL, `action` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `metadata` TEXT NOT NULL, PRIMARY KEY (`uuid`))');
  log.info('Migrated Cloud database from version 1 to 2');
});

final migrateCloudV2ToV3 = Migration(2, 3, (database) async {
  await database.execute('''
      ALTER TABLE Persona ADD COLUMN defaultAccount int DEFAULT(NULL);
      UPDATE Persona SET defaultAccount=1 ORDER BY id LIMIT 1;
      ''');
  log.info('Migrated Cloud database from version 2 to 3');
});

final migrateCloudV3ToV4 = Migration(3, 4, (database) async {
  final countTezosIndex = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='tezosIndex';"));
  log.info('Migrating Cloud database countTezosIndex: $countTezosIndex');
  if (countTezosIndex == 0) {
    await database.execute('''
      ALTER TABLE Persona ADD COLUMN tezosIndex INTEGER NOT NULL DEFAULT(1);
      ''');
  }

  final countETHINdex = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='ethereumIndex';"));
  log.info('Migrating Cloud database countETHINdex: $countETHINdex');
  if (countETHINdex == 0) {
    await database.execute('''
      ALTER TABLE Persona ADD COLUMN ethereumIndex INTEGER NOT NULL DEFAULT(1);
      ''');
  }
  log.info('Migrated Cloud database from version 3 to 4');
});

final migrateCloudV4ToV5 = Migration(4, 5, (database) async {
  final countTezosIndexes = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='tezosIndexes';"));
  log.info('Migrating Cloud database countTezosIndexes: $countTezosIndexes');
  if (countTezosIndexes == 0) {
    await database.execute('''
      ALTER TABLE Persona ADD COLUMN tezosIndexes TEXT;
      ''');
  }

  final countETHIndexes = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='ethereumIndexes';"));
  log.info('Migrating Cloud database countETHIndexes: $countETHIndexes');
  if (countETHIndexes == 0) {
    await database.execute('''
      ALTER TABLE Persona ADD COLUMN ethereumIndexes TEXT;
      ''');
  }

  await database.execute('''
      UPDATE Persona SET tezosIndexes = 
        (WITH RECURSIVE
          cnt(x, y, id) AS (
            SELECT 0, "", Persona.tezosIndex
            UNION ALL
            SELECT x + 1, y || "," || x || "", Persona.tezosIndex FROM cnt
            LIMIT 100
          )
        SELECT y FROM cnt WHERE x = (SELECT id FROM cnt WHERE x = 0));
      ''');

  log.info('Migrating Cloud database: executed tezosIndexes');

  await database.execute('''
      UPDATE Persona SET ethereumIndexes = 
        (WITH RECURSIVE
          cnt(x, y, id) AS (
            SELECT 0, "", Persona.ethereumIndex
            UNION ALL
            SELECT x + 1, y || "," || x || "", Persona.ethereumIndex FROM cnt
            LIMIT 100
          )
        SELECT y FROM cnt WHERE x = (SELECT id FROM cnt WHERE x = 0));
      ''');
  log.info('Migrated Cloud database from version 4 to 5');
});

final migrateCloudV5ToV6 = Migration(5, 6, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `WalletAddress` (`address` TEXT NOT NULL, `uuid` TEXT NOT NULL, `index` INTEGER NOT NULL, `cryptoType` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `isHidden` INTEGER NOT NULL, PRIMARY KEY (`address`))');

  log.info('Migrated Cloud database from version 5 to 6');
});

final migrateCloudV6ToV7 = Migration(6, 7, (database) async {
  final countNameCol = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('WalletAddress') WHERE name='name';"));
  log.info('Migrating Cloud database countNameCol: $countNameCol');
  if (countNameCol == 0) {
    await database.execute('''
      ALTER TABLE WalletAddress ADD COLUMN name TEXT;
      ''');
  }
  log.info('Migrated Cloud database from version 6 to 7');
});
final migrateCloudV7ToV8 = Migration(7, 8, (database) async {
  final countNameCol = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('WalletAddress') WHERE name='name';"));
  log.info('Migrating Cloud database countNameCol: $countNameCol');
  if (countNameCol == 0) {
    await database.execute('''
      ALTER TABLE WalletAddress ADD COLUMN name TEXT;
      ''');
  }
  log.info('Migrated Cloud database from version 7 to 8');
});

final migrateCloudV8ToV9 = Migration(8, 9, (database) async {
  // Check if 'accountOrder' column exists in 'Connection' table
  final countOrderColInConnection = sqflite.Sqflite.firstIntValue(
      await database.rawQuery(
          "SELECT COUNT(*) FROM pragma_table_info('Connection') WHERE name='accountOrder';"));

  if (countOrderColInConnection == 0) {
    await database
        .execute('ALTER TABLE Connection ADD COLUMN accountOrder INTEGER;');
  }

  // Check if 'accountOrder' column exists in 'WalletAddress' table
  final countOrderColInWalletAddress = sqflite.Sqflite.firstIntValue(
      await database.rawQuery(
          "SELECT COUNT(*) FROM pragma_table_info('WalletAddress') WHERE name='accountOrder';"));

  if (countOrderColInWalletAddress == 0) {
    await database
        .execute('ALTER TABLE WalletAddress ADD COLUMN accountOrder INTEGER;');
  }

  log.info('Migrated Cloud database from version 8 to 9');
});

final migrateCloudV9ToV10 = Migration(9, 10, (database) async {
  await database.execute('DROP TABLE IF EXISTS Audit;');
});

final cloudDatabaseMigrations = [
  migrateCloudV1ToV2,
  migrateCloudV2ToV3,
  migrateCloudV3ToV4,
  migrateCloudV4ToV5,
  migrateCloudV5ToV6,
  migrateCloudV6ToV7,
  migrateCloudV7ToV8,
  migrateCloudV8ToV9,
  migrateCloudV9ToV10,
];
