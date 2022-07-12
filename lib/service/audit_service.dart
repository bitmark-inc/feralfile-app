//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:convert';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:uuid/uuid.dart';

abstract class AuditService {
  void auditFirstLog();
  Future auditPersonaAction(String action, Persona? persona);
  Future auditSocialRecoveryAction(String action);
  Future<List<int>> export();
}

class AuditCategory {
  static const FullAccount = 'fullAccount';
  static const SocialRecovery = 'socialRecovery';
}

class AuditServiceImpl extends AuditService {
  CloudDatabase _cloudDB;

  AuditServiceImpl(
    this._cloudDB,
  );

  void auditFirstLog() async {
    final audits =
        await _cloudDB.auditDao.getAuditsBy(AuditCategory.FullAccount, 'init');
    if (audits.length > 0) return; // ignore if already init.

    final personas = await _cloudDB.personaDao.getPersonas();
    final metadata = {
      'accounts': await Future.wait(personas.map((e) async {
        final wallet = e.wallet();
        return {
          'uuid': e.uuid,
          'address': await wallet.getETHAddress(),
          'name': await wallet.getName(),
        };
      })),
    };

    final audit = Audit(
      uuid: Uuid().v4(),
      category: AuditCategory.FullAccount,
      action: 'init',
      createdAt: DateTime.now(),
      metadata: jsonEncode(metadata),
    );

    await _cloudDB.auditDao.insertAudit(audit);
  }

  Future auditPersonaAction(String action, Persona? persona) async {
    Map<String, dynamic> metadata = {};

    if (persona != null) {
      final wallet = persona.wallet();
      metadata = {
        'uuid': persona.uuid,
        'address': await wallet.getETHAddress(),
        'name': await wallet.getName(),
      };
    }

    final audit = Audit(
      uuid: Uuid().v4(),
      category: AuditCategory.FullAccount,
      action: action,
      createdAt: DateTime.now(),
      metadata: jsonEncode(metadata),
    );

    await _cloudDB.auditDao.insertAudit(audit);
  }

  Future auditSocialRecoveryAction(String action) async {
    final audit = Audit(
      uuid: Uuid().v4(),
      category: AuditCategory.SocialRecovery,
      action: action,
      createdAt: DateTime.now(),
      metadata: '',
    );

    await _cloudDB.auditDao.insertAudit(audit);
  }

  Future<List<int>> export() async {
    final audits = await _cloudDB.auditDao.getAudits();
    return utf8.encode('\n -- ACCOUNT AUDITS --\n' + jsonEncode(audits));
  }
}
