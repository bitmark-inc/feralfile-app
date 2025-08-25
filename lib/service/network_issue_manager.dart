import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/util/exception_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry.dart';
import 'package:synchronized/synchronized.dart';

class NetworkIssueManager {
  static const Duration _throttleDuration = Duration(seconds: 30);
  DateTime _lastErrorTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isShowingDialog = false;
  final _txDialogLock = Lock();
  static const maxRetries = 10;

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

  Future<void> showReceiveTimeoutWarning() async {
    if (_isShowingDialog) {
      return;
    }
    final context = injector<NavigationService>().navigatorKey.currentContext;
    if (context != null &&
        DateTime.now().difference(_lastErrorTime) > _throttleDuration) {
      _lastErrorTime = DateTime.now();
      await showErrorDialog(
        context,
        'request_issue'.tr(),
        'request_issue_desc'.tr(),
        'close'.tr(),
      );
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

  Future<T> retryOnConnectIssueTx<T>(FutureOr<T> Function() fn,
      {int maxRetries = maxRetries}) async {
    if (maxRetries > 0) {
      return await _txDialogLock
          .synchronized(() => _retryOnConnectIssue(fn, maxRetries: maxRetries));
    } else {
      return await fn();
    }
  }

  Future<T> _retryOnConnectIssue<T>(FutureOr<T> Function() fn,
      {int maxRetries = maxRetries, String? description}) async {
    try {
      return await fn();
    } on Exception catch (e) {
      log.info('Network issue detected: $e');
      unawaited(Sentry.captureException('Network issue detected: $e',
          stackTrace: StackTrace.current));
      if (e.isNetworkIssue && maxRetries > 0) {
        final context =
            injector<NavigationService>().navigatorKey.currentContext;
        if (context != null) {
          final desc = description ?? 'network_error_desc'.tr();
          final dialogResult = await showRetryDialog(
            context,
            description: desc,
            onRetry: () => true,
          );
          if (dialogResult == true) {
            return await _retryOnConnectIssue(fn,
                maxRetries: maxRetries - 1, description: desc);
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
