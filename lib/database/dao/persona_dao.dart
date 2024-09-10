//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';

@dao
abstract class PersonaDao {
  @Query('SELECT * FROM Persona')
  Future<List<Persona>> getPersonas();

  @Query('SELECT * FROM Persona WHERE defaultAccount=1')
  Future<List<Persona>> getDefaultPersonas();

  @Query('SELECT COUNT(*) FROM Persona')
  Future<int?> getPersonasCount();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPersona(Persona persona);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPersonas(List<Persona> personas);

  @Query('SELECT * FROM Persona WHERE uuid = :uuid')
  Future<Persona?> findById(String uuid);

  @update
  Future<void> updatePersona(Persona persona);

  @delete
  Future<void> deletePersona(Persona persona);

  @Query('DELETE FROM Persona')
  Future<void> removeAll();
}
