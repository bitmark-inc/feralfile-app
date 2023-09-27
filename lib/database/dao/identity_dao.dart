//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:floor/floor.dart';

@dao
abstract class IdentityDao {
  @Query('SELECT * FROM Identity')
  Future<List<Identity>> getIdentities();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertIdentity(Identity identity);

  @Query('SELECT * FROM Identity WHERE accountNumber = :accountNumber')
  Future<Identity?> findByAccountNumber(String accountNumber);

  @update
  Future<void> updateIdentity(Identity identity);

  @delete
  Future<void> deleteIdentity(Identity identity);

  @Query('DELETE FROM Identity')
  Future<void> removeAll();
}
