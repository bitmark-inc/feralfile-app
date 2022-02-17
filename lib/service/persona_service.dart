import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:uuid/uuid.dart';

abstract class PersonaService {
  WalletStorage? getActivePersona();

  List<WalletStorage> getPersonas();

  Future<void> createPersona(String name);
}

class PersonaServiceImpl extends PersonaService {
  ConfigurationService _configurationService;

  PersonaServiceImpl(this._configurationService);

  @override
  Future<void> createPersona(String name) async {
    log.info("PersonaService.createPersona: $name");
    final uuid = Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(name);

    List<String> personas = _configurationService.getPersonas().toList();
    personas.add(uuid);
    log.info("created a persona with uuid: $uuid");
    await _configurationService.setPersonas(personas);
  }

  @override
  WalletStorage? getActivePersona() {
    List<String> personas = _configurationService.getPersonas();

    if (personas.isNotEmpty) {
      return LibAukDart.getWallet(personas.first);
    } else {
      return null;
    }
  }

  @override
  List<WalletStorage> getPersonas() {
    return _configurationService
        .getPersonas()
        .map((uuid) => LibAukDart.getWallet(uuid))
        .toList();
  }
}
