import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';

extension WalletConnectExt on ConnectionRequest {
  bool get isSuspiciousDAppName {
    final remoteConfig = injector<RemoteConfigService>();
    final denyDAppUrls = remoteConfig.getConfig<List<dynamic>>(
        ConfigGroup.dAppUrls, ConfigKey.denyDAppList, []);

    if (denyDAppUrls.isEmpty) {
      return false;
    }
    return denyDAppUrls.contains(name);
  }
}
