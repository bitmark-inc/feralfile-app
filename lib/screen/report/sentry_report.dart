import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry/sentry_io.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:path/path.dart';

Future<String> reportSentry(Map payload) async {
  SentryId sentryId;
  if (payload["exception"] != null) {
    sentryId = await Sentry.captureException(
      payload["exception"],
      stackTrace: payload["stackTrace"],
      withScope: _addAttachment,
    );
  } else {
    final deviceID = await getDeviceID();
    sentryId =
        await Sentry.captureMessage(deviceID ?? "", withScope: _addAttachment);
  }

  /*
  Don't send userFeedback anymore
  final feedback = SentryUserFeedback(
    eventId: sentryId,
    comments: comments,
  );

  Sentry.captureUserFeedback(feedback);
  */

  return sentryId.toString();
}

Future _addAttachment(Scope scope) async {
  final logFilePath = await getLatestLogFile();
  final attachment =
      IoSentryAttachment.fromPath(logFilePath, filename: basename(logFilePath));
  scope.addAttachment(attachment);
}
