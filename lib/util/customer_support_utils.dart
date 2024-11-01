import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/customer_support.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

extension IssueExtension on Issue {
  bool get isAnonymous {
    final config = injector<ConfigurationService>();
    final userId = config.getAnonymousDeviceId();
    return userId != null && userId != this.userId;
  }
}

extension CustomerSupportHeaderExt on Map<String, dynamic> {
  bool get isAnonymous {
    final config = injector<ConfigurationService>();
    final userId = config.getAnonymousDeviceId();
    return userId != null && userId != this['x-device-id'];
  }
}
