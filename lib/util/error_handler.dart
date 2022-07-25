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
import 'package:autonomy_flutter/util/custom_exception.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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

ErrorEvent? translateError(Object exception) {
  if (exception is DioError) {
    if (exception.type != DioErrorType.response) {
      return ErrorEvent(null, "Network error",
          "Check your connection and try again.", ErrorItemState.tryAgain);
    }
  } else if (exception is CameraException) {
    return ErrorEvent(null, "Enable camera",
        "QR code scanning requires camera access.", ErrorItemState.camera);
  } else if (exception is PlatformException) {
    switch (exception.code) {
      case 'invalidDeeplink':
        return ErrorEvent(
            exception, "😵", "The link is not valid", ErrorItemState.close);
      default:
        break;
    }
  }

  return ErrorEvent(
    exception,
    "😵",
    "Autonomy has encountered an unexpected problem. We have automatically filed a crash report, and we will look into it. If you require further support or want to tell us more about the issue, please tap the button below.",
    ErrorItemState.getReport,
  );
}

bool onlySentryException(Object exception) {
  if (exception.toString().contains("Future already completed")) return true;

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
  final theme = AuThemeManager.get(AppTheme.sheetTheme);

  Vibrate.feedback(FeedbackType.warning);
  await showModalBottomSheet(
      context: context,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          color: Colors.transparent,
          child: ClipPath(
            clipper: AutonomyTopRightRectangleClipper(),
            child: Container(
              color: theme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: theme.textTheme.headline1),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 40),
                    Text(
                      description,
                      style: theme.textTheme.bodyText1,
                    ),
                    SizedBox(height: 40),
                    AuFilledButton(
                      text: defaultButton,
                      onPress: () {
                        Navigator.of(context).pop();
                        if (defaultButtonOnPress != null)
                          defaultButtonOnPress();
                      },
                      color: Colors.white,
                      textStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: "IBMPlexMono"),
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
                        textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: "IBMPlexMono"),
                      ),
                  ],
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      });

  await Future.delayed(Duration(seconds: 1), () {
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
      defaultButton = "CLOSE";
      break;

    case ErrorItemState.getReport:
      defaultButton = "GET SUPPORT";
      cancelButton = "CONTINUE";
      break;

    case ErrorItemState.tryAgain:
      defaultButton = "TRY AGAIN";
      break;

    case ErrorItemState.camera:
      defaultButton = "OPEN SETTINGS";
      defaultAction = () async => await openAppSettings();
      break;

    case ErrorItemState.seeAccount:
      defaultButton = "SEE ACCOUNT";
      cancelButton = "CLOSE";
      break;

    default:
      break;
  }
  showErrorDialog(context, event.title, event.message, defaultButton,
      defaultAction, cancelButton, cancelAction);
}

void showErrorDialogFromException(Object exception,
    {StackTrace? stackTrace, String? library}) async {
  final context = injector<NavigationService>().navigatorKey.currentContext;

  if (exception is PlatformException) {
    if (lastException != null && lastException?.message == exception.message) {
      return;
    }
    lastException = exception;
  } else if (context != null) {
    if (exception is AbortedException) {
      UIHelper.showInfoDialog(
          context, "Aborted", "The action was aborted by the user.",
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
      UIHelper.showInfoDialog(context, "😵", "The link is not valid",
          isDismissible: true, autoDismissAfter: 3);
      return;
    } else if (exception is ExpiredCodeLink) {
      UIHelper.showInfoDialog(context, "😵", "The link is not valid or expired",
          isDismissible: true, autoDismissAfter: 3);
      return;
    }
  }

  // avoid to bother user when user has just foregrounded the app.
  if (memoryValues.inForegroundAt != null &&
      DateTime.now()
              .subtract(Duration(seconds: 5))
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

      showErrorDiablog(
        context,
        event,
        defaultAction: () => Navigator.of(context).pushNamed(
          AppRouter.supportThreadPage,
          arguments: ExceptionErrorPayload(
              sentryID: sentryID, metadata: sentryMetadata),
        ),
      );
    } else {
      showErrorDiablog(
        context,
        event,
        defaultAction: null,
      );
    }
  }
}

void hideInfoDialog(BuildContext context) {
  Navigator.of(context).pop();
}

String getTezosErrorMessage(TezartNodeError err) {
  var message = "";
  if (err.message.contains("empty_implicit_contract") ||
      err.message.contains("balance_too_low")) {
    message =
        "Transaction is likely to fail. Please make sure you have enough of Tezos balance to perform this action.";
  } else if (err.message.contains("script_rejected")) {
    message = "The operation failed. Contract malformed or deprecated.";
  } else {
    message = "The operation failed with message: ${err.message}";
  }
  return message;
}
