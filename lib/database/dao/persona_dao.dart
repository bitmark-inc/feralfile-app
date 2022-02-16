import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';

@dao
abstract class PersonaDao {
  @Query('SELECT * FROM Persona')
  Future<List<Persona>> getPersonas();

  @insert
  Future<void> insertPersona(Persona persona);

  @Query('SELECT * FROM Persona WHERE uuid = :uuid')
  Future<Persona?> findById(String uuid);

  @update
  Future<void> updatePersona(Persona persona);
}
