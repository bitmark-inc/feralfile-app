import 'dart:async';

import 'package:autonomy_flutter/database/dao/asset_token_dao.dart';
import 'package:autonomy_flutter/database/dao/persona_dao.dart';
import 'package:autonomy_flutter/database/entity/asset_token.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'app_database.g.dart'; // the generated code will be there

@Database(version: 1, entities: [AssetToken])
abstract class AppDatabase extends FloorDatabase {
  AssetTokenDao get assetDao;
}

@TypeConverters([DateTimeConverter])
@Database(version: 1, entities: [Persona])
abstract class CloudDatabase extends FloorDatabase {
  PersonaDao get personaDao;
}
