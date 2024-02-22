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

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertPersonas(List<Persona> personas);

  @Query('DELETE FROM Persona')
  Future<void> removeAll();
}
