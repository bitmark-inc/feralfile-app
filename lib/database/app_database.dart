import 'dart:async';

import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/dao/identity_dao.dart';
import 'package:autonomy_flutter/database/dao/provenance_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/model/provenance.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'app_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter])
@Database(version: 6, entities: [AssetToken, Identity, Provenance])
abstract class AppDatabase extends FloorDatabase {
  AssetTokenDao get assetDao;
  IdentityDao get identityDao;
  ProvenanceDao get provenanceDao;

  Future<dynamic> removeAll() async {
    await provenanceDao.removeAll();
    await assetDao.removeAll();
    await identityDao.removeAll();
  }
}

final migrateV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
      'ALTER TABLE AssetToken ADD COLUMN lastActivityTime int DEFAULT(0)');
});

final migrateV2ToV3 = Migration(2, 3, (database) async {
  await database.execute(
      'CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`txID`))');
});

// For unknown reason, execute DROP then CREATE in same migration execution doesn't work.
// So I have to separate 2 versions
final migrateV3ToV4 = Migration(3, 4, (database) async {
  await database.execute("DROP TABLE IF EXISTS Provenance;");
});

final migrateV4ToV5 = Migration(4, 5, (database) async {
  await database.execute("""
      CREATE TABLE IF NOT EXISTS `Provenance` (`txID` TEXT NOT NULL, `type` TEXT NOT NULL, `blockchain` TEXT NOT NULL, `owner` TEXT NOT NULL, `timestamp` INTEGER NOT NULL, `txURL` TEXT NOT NULL, `tokenID` TEXT NOT NULL, FOREIGN KEY (`tokenID`) REFERENCES `AssetToken` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, PRIMARY KEY (`txID`));
      CREATE INDEX `index_Provenance_tokenID` ON `Provenance` (`tokenID`);""");
});

final migrateV5ToV6 = Migration(5, 6, (database) async {
  await database
      .execute('ALTER TABLE AssetToken ADD COLUMN hidden int DEFAULT(NULL)');
});
