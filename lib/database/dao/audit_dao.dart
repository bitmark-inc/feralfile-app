//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:autonomy_flutter/service/cloud_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuditDao {
  Future<List<Audit>> getAudits();

  Future<void> insertAudit(Audit audit);

  Future<void> insertAudits(List<Audit> audits);

  Future<List<Audit>> getAuditsBy(String category, String action);

  Future<void> removeAll();
}

class AuditDaoImp implements AuditDao {
  final _collectionName = 'audit';
  final CloudFirestoreService firestoreService;

  CollectionReference<Audit> get _collectionRef =>
      firestoreService.getCollection(_collectionName).withConverter<Audit>(
          fromFirestore: (snapshot, _) => Audit.fromJson(snapshot.data()!),
          toFirestore: (audit, _) => audit.toJson());

  AuditDaoImp(this.firestoreService);

  @override
  Future<List<Audit>> getAudits() async => _collectionRef.get().then(
        (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
      );

  @override
  Future<void> insertAudit(Audit audit) async {
    await _collectionRef.doc(audit.uuid).set(audit);
  }

  @override
  Future<void> insertAudits(List<Audit> audits) async {
    final batch = firestoreService.getBatch();
    for (final Audit audit in audits) {
      batch.set(_collectionRef.doc(audit.uuid), audit);
    }
    await batch.commit();
  }

  @override
  Future<List<Audit>> getAuditsBy(String category, String action) async {
    final query = _collectionRef
        .where('category', isEqualTo: category)
        .where('action', isEqualTo: action);
    return query.get().then(
          (snapshot) => snapshot.docs.map((e) => e.data()).toList(),
        );
  }

  @override
  Future<void> removeAll() async {
    final batch = firestoreService.getBatch();
    final snapshot = await _collectionRef.get();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
