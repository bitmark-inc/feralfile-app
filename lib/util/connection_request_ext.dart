import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/connection_request_args.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:walletconnect_flutter_v2/apis/core/verify/models/verify_context.dart';

extension ConnectionRequestExt on ConnectionRequest {
  Validation get validationState {
    final remoteConfig = injector<RemoteConfigService>();
    final denyDAppUrls = remoteConfig.getConfig<List<dynamic>>(
        ConfigGroup.dAppUrls, ConfigKey.denyDAppList, []);

    if (isBeaconConnect &&
        denyDAppUrls.isNotEmpty &&
        denyDAppUrls.contains(name)) {
      return Validation.SCAM;
    }

    if (name == 'Feral File') {
      return Validation.VALID;
    }

    return validation ?? Validation.VALID;
  }
}
