import 'package:autonomy_flutter/service/configuration_service.dart';

class MockConfigurationService extends ConfigurationServiceImpl {
  MockConfigurationService(super.preferences);

  @override
  bool didShowLiveWithArt() {
    return true; // Mock implementation always returns true
  }
}
