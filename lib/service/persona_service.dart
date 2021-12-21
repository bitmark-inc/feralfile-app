import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:uuid/uuid.dart';

abstract class PersonaService {
  WalletStorage? getActivePersona();
  Future<void> createPersona(String name);
}

class PersonaServiceImpl extends PersonaService {

  ConfigurationService _configurationService;

  PersonaServiceImpl(this._configurationService);

  @override
  Future<void> createPersona(String name) async {
    final uuid = Uuid().v4();
    final walletStorage = LibAukDart.getWallet(uuid);
    await walletStorage.createKey(name);

    List<String> personas = _configurationService.getPersonas().toList();
    personas.add(uuid);
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

}