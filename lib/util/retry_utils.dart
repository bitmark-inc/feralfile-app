import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class RetryUtils {
  static Future<T> retryOnConnectIssue<T>(FutureOr<T> Function() fn,
      {int maxRetries = 3}) async {
    try {
      return await fn();
    } on Exception catch (e) {
      if (e.isNetworkIssue && maxRetries > 0) {
        final context =
            injector<NavigationService>().navigatorKey.currentContext;
        if (context != null) {
          final dialogResult = await UIHelper.showRetryDialog<FutureOr<T>>(
            context,
            description: 'network_error_desc'.tr(),
            onRetry: () => retryOnConnectIssue(fn, maxRetries: maxRetries - 1),
          );
          if (dialogResult is FutureOr<T>) {
            return await dialogResult;
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }
}
