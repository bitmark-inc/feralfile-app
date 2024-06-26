import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
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

  static String getIndexID(String tokenId) {
    final contractAddress = JohnGerrardHelper.contractAddress;
    return 'eth-$contractAddress-$tokenId';
  }

  static List<CustomExhibitionNote> get customNote {
    final listCustomNote = injector<RemoteConfigService>()
        .getConfig<List<dynamic>?>(
            ConfigGroup.johnGerrard, ConfigKey.customNote, []);
    return listCustomNote
            ?.map((e) => CustomExhibitionNote.fromJson(e))
            .toList() ??
        [];
  }
}
