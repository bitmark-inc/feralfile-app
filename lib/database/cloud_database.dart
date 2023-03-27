//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/dao/audit_dao.dart';
import 'package:autonomy_flutter/database/dao/connection_dao.dart';
import 'package:autonomy_flutter/database/dao/persona_dao.dart';
import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'cloud_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter])
@Database(version: 5, entities: [Persona, Connection, Audit])
abstract class CloudDatabase extends FloorDatabase {
  PersonaDao get personaDao;

  ConnectionDao get connectionDao;

  AuditDao get auditDao;

  Future<dynamic> removeAll() async {
    await personaDao.removeAll();
    await connectionDao.removeAll();
    await auditDao.removeAll();
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
  await database.execute("""
      ALTER TABLE Persona ADD COLUMN tezosIndex INTEGER NOT NULL DEFAULT(1);
      """);
  await database.execute("""
      ALTER TABLE Persona ADD COLUMN ethereumIndex INTEGER NOT NULL DEFAULT(1);
      """);
});

final migrateCloudV4ToV5 = Migration(4, 5, (database) async {
  try {
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN tezosIndex INTEGER NOT NULL DEFAULT(1);
      """);
    await database.execute("""
      ALTER TABLE Persona ADD COLUMN ethereumIndex INTEGER NOT NULL DEFAULT(1);
      """);
  } catch (e) {

  }
  await database.execute("""
      ALTER TABLE Persona ADD COLUMN tezosIndexes TEXT;
      """);
  await database.execute("""
      ALTER TABLE Persona ADD COLUMN ethereumIndexes TEXT;
      """);

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
