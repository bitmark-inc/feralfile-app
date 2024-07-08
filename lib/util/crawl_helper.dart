import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

class CrawlHelper {
  static String? get exhibitionID {
    final config = injector<RemoteConfigService>()
        .getConfig(ConfigGroup.exhibition, ConfigKey.crawl, {});
    return config['exhibition_id'];
  }
}
