//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:floor/floor.dart';

@dao
abstract class AuditDao {
  @Query('SELECT * FROM Audit')
  Future<List<Audit>> getAudits();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAudit(Audit audit);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAudits(List<Audit> audits);

  @Query('SELECT * FROM Audit '
      'WHERE category = (:category) AND "action" = (:action)')
  Future<List<Audit>> getAuditsBy(String category, String action);

  @Query('DELETE FROM Audit')
  Future<void> removeAll();
}
