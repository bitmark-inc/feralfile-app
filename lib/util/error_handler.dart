import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screen/report/sentry_report_page.dart';

enum ErrorItemState {
  suggestReportIssue,
  report,
  thanks,
  close,
  tryAgain,
  settings,
}

class ErrorEvent {
  Object? err;
  String title;
  String message;
  ErrorItemState state;

  ErrorEvent(this.err, this.title, this.message, this.state);
}

PlatformException? lastException;

ErrorEvent transalateError(Object exception) {
  if (exception is DioError) {
    return ErrorEvent(null, "Network error",
        "Check your connection and try again.", ErrorItemState.tryAgain);
  } else {
    return ErrorEvent(
        exception,
        "Uh oh!",
        "Autonomy has encountered an unexpected problem. Please report the issue so that we can work on a fix.",
        ErrorItemState.suggestReportIssue);
  }
}

void showErrorDialog(BuildContext context, String title, String description,
    String defaultButton,
    [Function()? defaultButtonOnPress, String? cancelButton]) {
  final theme = AuThemeManager().getThemeData(AppTheme.sheetTheme);

  showModalBottomSheet(
      context: context,
      // isDismissible: false,
      enableDrag: false,
      // isScrollControlled: false,
      builder: (context) {
        return Container(
          color: Color(0xFF737373),
          child: ClipPath(
            clipper: AutonomyTopRightRectangleClipper(),
            child: Container(
              color: theme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
}

void showErrorDiablog(BuildContext context, ErrorEvent event,
    {Function()? defaultAction}) {
  String defaultButton = "";
  String? cancelButton;
  switch (event.state) {
    case ErrorItemState.close:
      defaultButton = "CLOSE";
      break;
    case ErrorItemState.suggestReportIssue:
      defaultButton = "REPORT ISSUE";
      cancelButton = "IGNORE";
      break;
    case ErrorItemState.tryAgain:
      defaultButton = "TRY AGAIN";
      break;
    default:
      break;
  }
  showErrorDialog(context, event.title, event.message, defaultButton,
      defaultAction, cancelButton);
}

void showErrorDialogFromException(Object exception) {
  if (exception is PlatformException &&
      lastException != null &&
      lastException?.message == exception.message) {
    return;
  }
  lastException = exception as PlatformException?;
  final event = transalateError(exception);
  final context = injector<NavigationService>().navigatorKey.currentContext;
  if (context != null) {
    showErrorDiablog(
      context,
      event,
      defaultAction: () => Navigator.of(context)
          .pushNamed(SentryReportPage.tag, arguments: exception),
    );
  }
}

void hideInfoDialog(BuildContext context) {
  Navigator.of(context).pop();
}
