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

  Future postLinkedAddresses() async {
    List<String> addresses = [];

    final personas = await _cloudDB.personaDao.getPersonas();

    if (personas.isEmpty) {
      log.info(
          '[AutonomyService] postLinkedAddresses; skip when there is no persona');
      return; // avoid re-create default account when forgot I existing
    }

    for (var persona in personas) {
      addresses.add(await persona.wallet().getETHEip55Address());
      addresses.add((await persona.wallet().getTezosWallet()).address);
      addresses.add(await persona.wallet().getBitmarkAddress());
    }

    final linkedAccounts = await _cloudDB.connectionDao.getLinkedAccounts();
    var linkedAccountNumbers =
        linkedAccounts.map((e) => e.accountNumber).toList();

    addresses.addAll(linkedAccountNumbers);

    return _autonomyApi.postLinkedAddressed({
      "addresses": addresses,
    });
  }

  Future clearLinkedAddresses() async {
    log.info('[AutonomyService] clearLinkedAddresses');
    return _autonomyApi.postLinkedAddressed({
      "addresses": [],
    });
  }
}
