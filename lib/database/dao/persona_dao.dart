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

  @Query("""
UPDATE Persona SET defaultAccount = 1 WHERE uuid = :uuid;
UPDATE Persona SET defaultAccount = 0 WHERE uuid != :uuid;
      """)
  Future<void> setUniqueDefaultAccount(String uuid);

  @Query('SELECT COUNT(*) FROM Persona')
  Future<int?> getPersonasCount();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPersona(Persona persona);

  @Query('SELECT * FROM Persona WHERE uuid = :uuid')
  Future<Persona?> findById(String uuid);

  @update
  Future<void> updatePersona(Persona persona);

  @delete
  Future<void> deletePersona(Persona persona);

  @Query('DELETE FROM Persona')
  Future<void> removeAll();
}
