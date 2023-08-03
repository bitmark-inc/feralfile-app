//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/dao/address_dao.dart';
import 'package:autonomy_flutter/database/dao/audit_dao.dart';
import 'package:autonomy_flutter/database/dao/connection_dao.dart';
import 'package:autonomy_flutter/database/dao/persona_dao.dart';
import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'entity/wallet_address.dart';

part 'cloud_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter])
@Database(version: 8, entities: [Persona, Connection, Audit, WalletAddress])
abstract class CloudDatabase extends FloorDatabase {
  PersonaDao get personaDao;

  ConnectionDao get connectionDao;

  AuditDao get auditDao;

  WalletAddressDao get addressDao;

  Future<dynamic> removeAll() async {
    await personaDao.removeAll();
    await connectionDao.removeAll();
    await auditDao.removeAll();
    await addressDao.removeAll();
  }

  Future<void> copyDataFrom(CloudDatabase source) async {
    await source.personaDao.getPersonas().then((personas) async {
      await personaDao.insertPersonas(personas);
    });
    await source.connectionDao.getConnections().then((connections) async {
      await connectionDao.insertConnections(connections);
    });
    await source.auditDao.getAudits().then((audits) async {
      await auditDao.insertAudits(audits);
    });
    await source.addressDao.getAllAddresses().then((addresses) async {
      await addressDao.insertAddresses(addresses);
    });
  }
}

final migrateCloudV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Audit` (`uuid` TEXT NOT NULL, `category` TEXT NOT NULL, `action` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `metadata` TEXT NOT NULL, PRIMARY KEY (`uuid`))');
});

final migrateCloudV2ToV3 = Migration(2, 3, (database) async {
  await database.execute("""
      ALTER TABLE Persona ADD COLUMN defaultAccount int DEFAULT(NULL);
      UPDATE Persona SET defaultAccount=1 ORDER BY id LIMIT 1;
      """);
});

final migrateCloudV3ToV4 = Migration(3, 4, (database) async {
  final countTezosIndex = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='tezosIndex';"));
  if (countTezosIndex == 0) {
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN tezosIndex INTEGER NOT NULL DEFAULT(1);
      """);
  }

  final countETHINdex = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='ethereumIndex';"));
  if (countETHINdex == 0) {
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN ethereumIndex INTEGER NOT NULL DEFAULT(1);
      """);
  }
});

final migrateCloudV4ToV5 = Migration(4, 5, (database) async {
  final countTezosIndexes = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='tezosIndexes';"));
  if (countTezosIndexes == 0) {
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN tezosIndexes TEXT;
      """);
  }

  final countETHIndexes = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('Persona') WHERE name='ethereumIndexes';"));
  if (countETHIndexes == 0) {
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN ethereumIndexes TEXT;
      """);
  }

  await database.execute("""
      UPDATE Persona SET tezosIndexes = 
        (WITH RECURSIVE
          cnt(x, y, id) AS (
            SELECT 0, "", Persona.tezosIndex
            UNION ALL
            SELECT x + 1, y || "," || x || "", Persona.tezosIndex FROM cnt
            LIMIT 100
          )
        SELECT y FROM cnt WHERE x = (SELECT id FROM cnt WHERE x = 0));
      """);

  await database.execute("""
      UPDATE Persona SET ethereumIndexes = 
        (WITH RECURSIVE
          cnt(x, y, id) AS (
            SELECT 0, "", Persona.ethereumIndex
            UNION ALL
            SELECT x + 1, y || "," || x || "", Persona.ethereumIndex FROM cnt
            LIMIT 100
          )
        SELECT y FROM cnt WHERE x = (SELECT id FROM cnt WHERE x = 0));
      """);
});

final migrateCloudV5ToV6 = Migration(5, 6, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `WalletAddress` (`address` TEXT NOT NULL, `uuid` TEXT NOT NULL, `index` INTEGER NOT NULL, `cryptoType` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `isHidden` INTEGER NOT NULL, PRIMARY KEY (`address`))');
  final personaTable = await database.query("Persona");
  final personas = personaTable.map((e) => Persona.fromJson(e)).toList();
  for (var persona in personas) {
    List<String>? tezIndexesStr = (persona.tezosIndexes ?? "").split(',');
    tezIndexesStr.removeWhere((element) => element.isEmpty);
    final tezIndexes = tezIndexesStr.map((e) => int.parse(e)).toList();
    for (var index in tezIndexes) {
      await database.insert(
          "WalletAddress",
          {
            "address": await persona.wallet().getTezosAddress(index: index),
            "uuid": persona.uuid,
            "index": index,
            "cryptoType": CryptoType.XTZ.source,
            "createdAt": persona.createdAt.millisecondsSinceEpoch,
            "isHidden": 0,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
    }
    List<String>? ethIndexesStr = (persona.ethereumIndexes ?? "").split(',');

    ethIndexesStr.removeWhere((element) => element.isEmpty);
    final ethIndexes = ethIndexesStr.map((e) => int.parse(e)).toList();
    for (var index in ethIndexes) {
      await database.insert(
          "WalletAddress",
          {
            "address": await persona.wallet().getETHEip55Address(index: index),
            "uuid": persona.uuid,
            "index": index,
            "cryptoType": CryptoType.ETH.source,
            "createdAt": persona.createdAt.millisecondsSinceEpoch,
            "isHidden": 0,
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.ignore);
    }
  }
});

final migrateCloudV6ToV7 = Migration(6, 7, (database) async {
  final countNameCol = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('WalletAddress') WHERE name='name';"));
  if (countNameCol == 0) {
    await database.execute("""
      ALTER TABLE WalletAddress ADD COLUMN name TEXT;
      """);
  }
});
final migrateCloudV7ToV8 = Migration(7, 8, (database) async {
  final countNameCol = sqflite.Sqflite.firstIntValue(await database.rawQuery(
      "SELECT COUNT(*) FROM pragma_table_info('WalletAddress') WHERE name='name';"));
  if (countNameCol == 0) {
    await database.execute("""
      ALTER TABLE WalletAddress ADD COLUMN name TEXT;
      """);
  }
});
