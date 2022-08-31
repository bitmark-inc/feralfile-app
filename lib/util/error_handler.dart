//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/customer_support/support_thread_page.dart';
import 'package:autonomy_flutter/screen/report/sentry_report.dart';
import 'package:autonomy_flutter/service/aws_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';

import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tezart/tezart.dart';

enum ErrorItemState {
  getReport,
  report,
  thanks,
  close,
  tryAgain,
  settings,
  camera,
  seeAccount,
}

class ErrorEvent {
  Object? err;
  String title;
  String message;
  ErrorItemState state;

  ErrorEvent(this.err, this.title, this.message, this.state);
}

PlatformException? lastException;

extension DioErrorEvent on DioError {
  ErrorEvent? get errorEvent {
    log.info("Dio Error: $this");
    switch (type) {
      case DioErrorType.connectTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return ErrorEvent(null, "Connect timeout",
            "Check your connection and try again.", ErrorItemState.tryAgain);
      case DioErrorType.response:
        if ((response?.statusCode ?? 0) / 100 == 5) {
          return ErrorEvent(
              null,
              "Server error",
              "We apologise and are fixing the problem.\nPlease try again at later stage.",
              ErrorItemState.close);
        } else {
          return null;
        }
      default:
        return null;
    }
  }
}

ErrorEvent? translateError(Object exception) {
  if (exception is DioError) {
    final dioErrorEvent = exception.errorEvent;
    if (dioErrorEvent != null) {
      return dioErrorEvent;
    }
  } else if (exception is CameraException) {
    return ErrorEvent(null, "enable_camera".tr(), "qr_scan_require".tr(),
        ErrorItemState.camera);
  } else if (exception is PlatformException) {
    switch (exception.code) {
      case 'invalidDeeplink':
        return ErrorEvent(
            exception, "😵", "link_not_valid".tr(), ErrorItemState.close);
      default:
        break;
    }
  } else if (exception is LinkingFailedException) {
    return ErrorEvent(
        exception,
        "🤔",
        "problem_connect_wallet".tr(),
        //"There seems to be a problem connecting to your wallet.. We’ve automatically filed a bug report and will look into it. If you require further support or want to tell us more about the issue, please tap the button below.",
        ErrorItemState.getReport);
  }

  // Ignore other errors
  // return ErrorEvent(
  //   exception,
  //   "😵",
  //   "Autonomy has encountered an unexpected problem. We have automatically filed a crash report, and we will look into it. If you require further support or want to tell us more about the issue, please tap the button below.",
  //   ErrorItemState.getReport,
  // );

  return null;
}

bool onlySentryException(Object exception) {
  if (exception.toString().contains("Future already completed") ||
      exception.toString().contains("Out of Memory")) {
    return true;
  }

  if (exception is PlatformException) {
    switch (exception.code) {
      case 'VideoError':
        return true;
      default:
        return false;
    }
  }

  return false;
}

DateTime? isShowErrorDialogWorking;

Future showErrorDialog(BuildContext context, String title, String description,
    String defaultButton,
    [Function()? defaultButtonOnPress,
    String? cancelButton,
    Function()? cancelButtonOnPress]) async {
  if (isShowErrorDialogWorking != null &&
      isShowErrorDialogWorking!
              .add(const Duration(seconds: 2))
              .compareTo(DateTime.now()) >
          0) {
    log.info("showErrorDialog is working");
    return;
  }

  isShowErrorDialogWorking = DateTime.now();
  final theme = Theme.of(context);

  Vibrate.feedback(FeedbackType.warning);
  await showModalBottomSheet(
      context: context,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.isMobile
              ? double.infinity
              : Constants.maxWidthModalTablet),
      builder: (context) {
        return Container(
          color: Colors.transparent,
          child: ClipPath(
            clipper: AutonomyTopRightRectangleClipper(),
            child: Container(
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: theme.primaryTextTheme.headline1),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Text(
                      description,
                      style: theme.primaryTextTheme.bodyText1,
                    ),
                    const SizedBox(height: 40),
                    AuFilledButton(
                      text: defaultButton,
                      onPress: () {
                        Navigator.of(context).pop();
                        if (defaultButtonOnPress != null) {
                          defaultButtonOnPress();
                        }
                      },
                      color: theme.colorScheme.secondary,
                      textStyle: theme.textTheme.button,
                    ),
                    if (cancelButton != null)
                      AuFilledButton(
                        text: cancelButton,
                        onPress: () {
                          Navigator.of(context).pop();

                          if (cancelButtonOnPress != null) {
                            cancelButtonOnPress();
                          }
                        },
                        textStyle: theme.primaryTextTheme.button,
                      ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      });

  await Future.delayed(const Duration(seconds: 1), () {
    isShowErrorDialogWorking = null;
  });
}

void showErrorDiablog(
  BuildContext context,
  ErrorEvent event, {
  Function()? defaultAction,
  Function()? cancelAction,
}) {
  String defaultButton = "";
  String? cancelButton;
  switch (event.state) {
    case ErrorItemState.close:
      defaultButton = "close".tr();
      break;

    case ErrorItemState.getReport:
      defaultButton = "get_support".tr();
      cancelButton = "continue".tr();
      break;

    case ErrorItemState.tryAgain:
      defaultButton = "try_again".tr();
      break;

    case ErrorItemState.camera:
      defaultButton = "open_settings".tr();
      defaultAction = () async => await openAppSettings();
      break;

    case ErrorItemState.seeAccount:
      defaultButton = "see_account".tr();
      cancelButton = "close".tr();
      break;

    default:
      break;
  }
  showErrorDialog(context, event.title, event.message, defaultButton,
      defaultAction, cancelButton, cancelAction);
}

void showErrorDialogFromException(Object exception,
    {StackTrace? stackTrace, String? library}) async {
  final navigationService = injector<NavigationService>();
  final context = navigationService.navigatorKey.currentContext;

  if (exception is PlatformException) {
    if (lastException != null && lastException?.message == exception.message) {
      return;
    }
    lastException = exception;
  } else if (context != null) {
    if (exception is AbortedException) {
      UIHelper.showInfoDialog(context, "aborted".tr(), "action_aborted".tr(),
          isDismissible: true, autoDismissAfter: 3);
      return;
    } else if (exception is RequiredPremiumFeature) {
      UIHelper.showFeatureRequiresSubscriptionDialog(
          context, exception.feature);
      return;
    } else if (exception is AlreadyLinkedException) {
      UIHelper.showAlreadyLinked(context, exception.connection);
      return;
    } else if (exception is InvalidDeeplink) {
      UIHelper.showInfoDialog(context, "😵", "link_not_valid".tr(),
          isDismissible: true, autoDismissAfter: 3);
      return;
    }
  }

  // avoid to bother user when user has just foregrounded the app.
  if (memoryValues.inForegroundAt != null &&
      DateTime.now()
              .subtract(const Duration(seconds: 5))
              .compareTo(memoryValues.inForegroundAt!) <
          0) {
    Sentry.captureException(exception,
        stackTrace: stackTrace,
        withScope: (Scope? scope) => scope?.setTag("library", library ?? ''));
    return;
  }

  log.warning("Unhandled error: $exception", exception);
  injector<AWSService>().storeEventWithDeviceData("unhandled_error",
      data: {"message": exception.toString()});

  if (library != null || onlySentryException(exception)) {
    // Send error directly to Sentry if it comes from specific libraries
    Sentry.captureException(exception,
        stackTrace: stackTrace,
        withScope: (Scope? scope) => scope?.setTag("library", library ?? ''));
    return;
  }

  final event = translateError(exception);

  if (context != null && event != null) {
    if (event.state == ErrorItemState.getReport) {
      final sentryID = await reportSentry(
          {"exception": exception, "stackTrace": stackTrace});
      var sentryMetadata = "";
      if (sentryID == "00000000000000000000000000000000") {
        sentryMetadata = exception.toString();
      }

      navigationService.showErrorDialog(
        event,
        defaultAction: () => Navigator.of(context).pushNamed(
          AppRouter.supportThreadPage,
          arguments: ExceptionErrorPayload(
              sentryID: sentryID, metadata: sentryMetadata),
        ),
      );
    } else {
      navigationService.showErrorDialog(event);
    }
  } else {
    Sentry.captureException(exception,
        stackTrace: stackTrace,
        withScope: (Scope? scope) => scope?.setTag("library", library ?? ''));
  }
}

void hideInfoDialog(BuildContext context) {
  Navigator.of(context).pop();
}

String getTezosErrorMessage(TezartNodeError err) {
  var message = "";
  if (err.message.contains("empty_implicit_contract") ||
      err.message.contains("balance_too_low")) {
    message = "not_enough_tz".tr();
    //"Transaction is likely to fail. Please make sure you have enough of Tezos balance to perform this action.";
  } else if (err.message.contains("script_rejected")) {
    message = "contract_malformed"
        .tr(); // "The operation failed. Contract malformed or deprecated.";
  } else {
    message = "operation_failed_with".tr(args: [err.message]);
  }
  return message;
}
