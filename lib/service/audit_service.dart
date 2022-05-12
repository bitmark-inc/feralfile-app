import 'dart:convert';

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:uuid/uuid.dart';

abstract class AuditService {
  void auditFirstLog();
  Future audiPersonaAction(String action, Persona? persona);
  Future<List<int>> export();
}

class AuditCategory {
  static const FullAccount = 'fullAccount';
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

  Future audiPersonaAction(String action, Persona? persona) async {
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

  Future<List<int>> export() async {
    final audits = await _cloudDB.auditDao.getAudits();
    return utf8.encode('\n -- ACCOUNT AUDITS --\n' + jsonEncode(audits));
  }
}
