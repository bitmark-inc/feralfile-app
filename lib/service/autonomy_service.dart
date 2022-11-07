//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/gateway/autonomy_api.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/wallet_storage_ext.dart';

abstract class AutonomyService {
  Future postLinkedAddresses();
  Future clearLinkedAddresses();
}

class AutonomyServiceImpl extends AutonomyService {
  final CloudDatabase _cloudDB;
  final AutonomyApi _autonomyApi;

  AutonomyServiceImpl(this._cloudDB, this._autonomyApi);

  @override
  Future postLinkedAddresses() async {
    List<String> addresses = [];

    final personas = await _cloudDB.personaDao.getPersonas();

    if (personas.isEmpty) {
      log.info(
          '[AutonomyService] postLinkedAddresses;'
              ' skip when there is no persona');
      return; // avoid re-create default account when forgot I existing
    }

    for (var persona in personas) {
      if (!await persona.wallet().isWalletCreated()) continue;
      addresses.add(await persona.wallet().getETHEip55Address());
      addresses.add(await persona.wallet().getTezosAddress());
      addresses.add(await persona.wallet().getBitmarkAddress());
    }

    final linkedAccounts =
        await _cloudDB.connectionDao.getUpdatedLinkedAccounts();
    var linkedAccountNumbers =
        linkedAccounts.expand((e) => e.accountNumbers).toList();

    addresses.addAll(linkedAccountNumbers);

    return _autonomyApi.postLinkedAddressed({
      "addresses": addresses,
    });
  }

  @override
  Future clearLinkedAddresses() async {
    log.info('[AutonomyService] clearLinkedAddresses');
    return _autonomyApi.postLinkedAddressed({
      "addresses": [],
    });
  }
}
