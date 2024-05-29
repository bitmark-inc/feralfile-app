import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NetworkIssueManager {
  static const Duration _throttleDuration = Duration(minutes: 2);
  DateTime _lastErrorTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isShowingDialog = false;

  Future<void> showNetworkIssueWarning() async {
    if (_isShowingDialog) {
      return;
    }
    final context = injector<NavigationService>().navigatorKey.currentContext;
    if (context != null &&
        DateTime.now().difference(_lastErrorTime) > _throttleDuration) {
      _lastErrorTime = DateTime.now();
      await UIHelper.showRetryDialog(context,
          description: 'network_error_desc'.tr());
    }
  }

  Future<T?> showRetryDialog<T>(BuildContext context,
      {required String description,
      FutureOr<T> Function()? onRetry,
      ValueNotifier<bool>? dynamicRetryNotifier}) async {
    _isShowingDialog = true;
    final result = await UIHelper.showRetryDialog<T>(context,
        description: description,
        onRetry: onRetry,
        dynamicRetryNotifier: dynamicRetryNotifier);
    _isShowingDialog = false;
    return result;
  }

  Future<T> retryOnConnectIssue<T>(FutureOr<T> Function() fn,
      {int maxRetries = 3}) async {
    try {
      return await fn();
    } on Exception catch (e) {
      if (e.isNetworkIssue && maxRetries > 0) {
        final context =
            injector<NavigationService>().navigatorKey.currentContext;
        if (context != null) {
          final dialogResult = await showRetryDialog<FutureOr<T>>(
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
