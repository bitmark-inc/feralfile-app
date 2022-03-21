import 'dart:async';

import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/dao/identity_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'app_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter])
@Database(version: 2, entities: [AssetToken, Identity])
abstract class AppDatabase extends FloorDatabase {
  AssetTokenDao get assetDao;
  IdentityDao get identityDao;
}

final migrationToV1ToV2 = Migration(1, 2, (database) async {
  await database.execute(
      'ALTER TABLE AssetToken ADD COLUMN lastActivityTime int DEFAULT(0)');
});
