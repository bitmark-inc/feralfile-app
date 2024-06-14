import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

class JohnGerrardHelper {
  static String? get contractAddress {
    final config = injector<RemoteConfigService>()
        .getConfig(ConfigGroup.exhibition, ConfigKey.johnGerrard, {});
    return config['contract_address'];
  }

  static String? get exhibitionID {
    final config = injector<RemoteConfigService>()
        .getConfig(ConfigGroup.exhibition, ConfigKey.johnGerrard, {});
    return config['exhibition_id'];
  }

  static List<dynamic> get seriesIDs {
    final listSeriesIds = injector<RemoteConfigService>()
        .getConfig<List<dynamic>?>(
            ConfigGroup.johnGerrard, ConfigKey.seriesIds, []);
    return listSeriesIds ?? [];
  }

  static List<dynamic> get assetIDs {
    final listAssetIds = injector<RemoteConfigService>()
        .getConfig<List<dynamic>?>(
            ConfigGroup.johnGerrard, ConfigKey.assetIds, []);
    return listAssetIds ?? [];
  }
}
