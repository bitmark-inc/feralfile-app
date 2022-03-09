import 'package:autonomy_flutter/util/log.dart';
import 'package:sentry/sentry_io.dart';
import 'package:autonomy_flutter/util/device.dart';
import 'package:path/path.dart';

Future reportSentry(Map payload, String comments) async {
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

  final feedback = SentryUserFeedback(
    eventId: sentryId,
    comments: comments,
  );
  Sentry.captureUserFeedback(feedback);
}

Future reportRenderingIssue(String tokenID, List<String> issuedTopics) async {
  final title = "[RenderingIssue] Token $tokenID";

  final deviceID = await getDeviceID();

  SentryId sentryId =
      await Sentry.captureMessage(title + " $deviceID", withScope: (scope) {
    _addAttachment(scope);
    scope.fingerprint = [tokenID + issuedTopics.join(",")];
    scope.setTag("issuedToken", tokenID);
    for (var topic in issuedTopics) {
      scope.setTag("issuedTopics-$topic", 'true');
    }
  });

  final message =
      "Issues Token: $tokenID \n Issued Topics: ${issuedTopics.join(', ')}";
  final feedback = SentryUserFeedback(eventId: sentryId, comments: message);

  Sentry.captureUserFeedback(feedback);
}

Future _addAttachment(Scope scope) async {
  final logFilePath = await getLatestLogFile();
  final attachment =
      IoSentryAttachment.fromPath(logFilePath, filename: basename(logFilePath));
  scope.addAttachment(attachment);
}
