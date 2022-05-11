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
@Database(version: 3, entities: [Persona, Connection, Audit])
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
  await database
      .execute("""
      ALTER TABLE Persona ADD COLUMN defaultAccount int DEFAULT(NULL);
      UPDATE Persona SET defaultAccount=1 ORDER BY id LIMIT 1;
      """);
});