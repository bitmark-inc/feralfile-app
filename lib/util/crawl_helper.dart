import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

class CrawlHelper {
  static String? get exhibitionID {
    final config = injector<RemoteConfigService>()
        .getConfig<Map<String, dynamic>>(
            ConfigGroup.exhibition, ConfigKey.crawl, {});
    return config['exhibition_id'] as String?;
  }

  static String? get mergeSeriesID {
    final config = injector<RemoteConfigService>()
        .getConfig<Map<String, dynamic>>(
            ConfigGroup.exhibition, ConfigKey.crawl, {});
    return config['merge_series_id'] as String?;
  }
}
