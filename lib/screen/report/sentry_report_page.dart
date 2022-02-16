import 'package:autonomy_flutter/util/device.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/au_filled_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:sentry/sentry_io.dart';

import 'package:path/path.dart';

class SentryReportPage extends StatefulWidget {
  static const String tag = 'sentry_report';

  final Object? payload;

  const SentryReportPage({Key? key, required this.payload}) : super(key: key);
  @override
  State<SentryReportPage> createState() => _SentryReportPageState(this.payload);
}

class _SentryReportPageState extends State<SentryReportPage> {
  final Object? payload;
  TextEditingController _feedbackTextController = TextEditingController();

  _SentryReportPageState(this.payload);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Report issue",
              style: appTextTheme.headline1,
            ),
            SizedBox(height: 40.0),
            AuTextField(
              title: "",
              placeholder: "Describe your issue here",
              expanded: true,
              keyboardType: TextInputType.multiline,
              controller: _feedbackTextController,
            ),
            SizedBox(height: 40.0),
            AuFilledButton(
              text: "SUBMIT",
              onPress: () {
                _reportSentry();
                Navigator.of(context).pop();
              },
              textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: "IBMPlexMono"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "CANCEL",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: "IBMPlexMono"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportSentry() async {
    SentryId sentryId;
    if (payload != null) {
      sentryId = await Sentry.captureException(
        payload,
        withScope: _addAttachment,
      );
    } else {
      final deviceID = await getDeviceID();
      sentryId = await Sentry.captureMessage(deviceID ?? "",
          withScope: _addAttachment);
    }

    final feedback = SentryUserFeedback(
      eventId: sentryId,
      comments: _feedbackTextController.text,
    );
    Sentry.captureUserFeedback(feedback);
  }

  void _addAttachment(Scope scope) async {
    final logFilePath = await getLatestLogFile();
    final attachment = IoSentryAttachment.fromPath(logFilePath,
        filename: basename(logFilePath));
    scope.addAttachment(attachment);
  }
}
