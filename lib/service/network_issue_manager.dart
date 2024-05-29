import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class NetworkIssueManager {
  static const Duration _throttleDuration = Duration(minutes: 2);
  DateTime _lastErrorTime = DateTime.fromMillisecondsSinceEpoch(0);


  Future<void> showNetworkIssueWarning() async {
    final context = injector<NavigationService>().navigatorKey.currentContext;
    if (context != null &&
        DateTime.now().difference(_lastErrorTime) > _throttleDuration) {
      _lastErrorTime = DateTime.now();
      await UIHelper.showRetryDialog(context,
          description: 'network_error_desc'.tr());
    }
  }
}
