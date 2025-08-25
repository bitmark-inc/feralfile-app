import 'package:autonomy_flutter/service/channel_service.dart';

class MockChannelService extends ChannelService {
  @override
  Future<Map<String, List<String>>> exportMnemonicForAllPersonaUUIDs() async {
    return {
      'persona1': [
        'word1',
        'word2',
        'word3',
        'word4',
        'word5',
        'word6',
        'word7',
        'word8',
        'word9',
        'word10',
        'word11',
        'word12'
      ],
    };
  }

  @override
  Future<void> exportMnemonicForPersonaUUID(String personaUUID) async {}

  @override
  Future<void> importMnemonicForPersonaUUID(
      String personaUUID, List<String> mnemonic) async {}

  @override
  Future<void> deleteMnemonicForPersonaUUID(String personaUUID) async {}

  @override
  Future<void> deleteAllMnemonic() async {}
}
