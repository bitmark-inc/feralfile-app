import 'dart:convert';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/persona_service.dart';
import 'package:flutter/services.dart';

class MigrationUtil {
  static const MethodChannel _channel = const MethodChannel('migration_util');

  MigrationUtil();

  Future<String> _getExistingUuids() async {
    final String data = await _channel.invokeMethod('getExistingUuids', {});
    return data;
  }

  Future<void> migrateIfNeeded() async {
    final personaService = injector<PersonaService>();
    final configurationService = injector<ConfigurationService>();

    final jsonString = await _getExistingUuids();
    if (jsonString.isNotEmpty && personaService.getActivePersona() == null) {
      // Do migration
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final uuids = json["personas"] ?? [];
      if (uuids.isNotEmpty) {
        // The android app is currently supporting single persona only.
        final uuid = uuids.first;
        List<String> personas = configurationService.getPersonas().toList();
        personas.add(uuid);
        await configurationService.setPersonas(personas);
      }
    }
  }

}