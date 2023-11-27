//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:autonomy_flutter/database/dao/firestore_address_dao.dart';
import 'package:autonomy_flutter/database/dao/firestore_audit_dao.dart';
import 'package:autonomy_flutter/database/dao/firestore_connection_dao.dart';
import 'package:autonomy_flutter/database/dao/firestore_persona_dao.dart';

class CloudDatabase {
  FirestorePersonaDao personaDao;

  FirestoreConnectionDao connectionDao;

  FirestoreAuditDao auditDao;

  FirestoreWalletAddressDao addressDao;

  CloudDatabase(
    this.personaDao,
    this.connectionDao,
    this.auditDao,
    this.addressDao,
  );

  Future<dynamic> removeAll() async {
    await personaDao.removeAll();
    await connectionDao.removeAll();
    await auditDao.removeAll();
    await addressDao.removeAll();
  }

  Future<void> copyDataFrom(CloudDatabase source) async {
    await source.personaDao.getPersonas().then((personas) async {
      await personaDao.insertPersonas(personas);
    });
    await source.connectionDao.getConnections().then((connections) async {
      await connectionDao.insertConnections(connections);
    });
    await source.auditDao.getAudits().then((audits) async {
      await auditDao.insertAudits(audits);
    });
    await source.addressDao.getAllAddresses().then((addresses) async {
      await addressDao.insertAddresses(addresses);
    });
  }
}
