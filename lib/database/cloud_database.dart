import 'dart:async';

import 'package:autonomy_flutter/database/dao/connection_dao.dart';
import 'package:autonomy_flutter/database/dao/persona_dao.dart';
import 'package:autonomy_flutter/database/entity/connection.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'cloud_database.g.dart'; // the generated code will be there

@TypeConverters([DateTimeConverter])
@Database(version: 1, entities: [Persona, Connection])
abstract class CloudDatabase extends FloorDatabase {
  PersonaDao get personaDao;
  ConnectionDao get connectionDao;
}
